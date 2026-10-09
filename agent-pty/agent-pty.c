/*
 * agent-pty — run a program on its own pty and turn the Program Status reports
 * (OSC 7501) it prints into the tmux per-tab agent dot.
 *
 *   agent-pty <command> [args...]
 *
 * Why a pty in the middle: Claude Code (>= 2.1.295) only emits OSC 7501 after
 * the terminal answers its `OSC 7501 ; ?` probe, and tmux (3.7c) neither answers
 * nor forwards it — so inside tmux Claude stays silent. This sits between tmux
 * and Claude, answers the probe, swallows every OSC 7501 sequence and hands the
 * state to `agent-state`. Everything else passes through byte for byte.
 *
 * Spec: https://superlogical.com/rex/docs/build/program-status
 *
 *   root record             @agent_state
 *   working                 running
 *   blocked / error         needs-input     (also: any child record blocked)
 *   done                    done
 *   idle                    idle, or none before the first turn (startup)
 *   clear (no id) / exit    none
 *
 * Child records (an `id`) are Claude's subagents; the live ones become
 * @agent_subagents, the "+N" in the status bar.
 *
 * The tmux calls run in a forked worker that reads one line per change from a
 * pipe and runs them in order: never inline, so a slow tmux never freezes
 * Claude's screen, and never in parallel, so `working` can't land after `done`.
 *
 * Process tree: this process (on the tmux pane's tty) → a job-control parent
 * that leads the inner pty's session → the program, in a foreground group of its
 * own so its Ctrl+Z suspends (see job_control).
 *
 * The binary is installed as `.../agent-pty/claude` so that tmux sees a process
 * called "claude" in the pane (automatic-rename, tmux-pane-close's ps -t scan):
 * Claude itself now lives on the inner pty, invisible to both.
 *
 * Verified against Claude Code 2.1.295: idle at startup, working (with a msg),
 * blocked kind=permission / kind=question, done, idle on an ESC interrupt, one
 * child record per background subagent cleared when it finishes. Codex (0.162)
 * does not speak OSC 7501 yet; it keeps its hooks.
 *
 * Built by .chezmoiscripts/run_onchange_after_build-agent-pty.sh.tmpl.
 */
#define _DEFAULT_SOURCE
#define _DARWIN_C_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <termios.h>
#include <unistd.h>
#ifdef __APPLE__
#include <util.h>
#else
#include <pty.h>
#endif

#define PREFIX "\033]7501;"
#define PREFIX_LEN 7
#define BODY_MAX 4096 /* the spec's whole-sequence limit */
#define MAX_CHILDREN 256

static int master_fd = -1, sig_pipe[2] = {-1, -1}, worker_fd = -1;
static pid_t child = -1;
static struct termios saved_tio;
static int have_tio;

/* ── signals → self-pipe ─────────────────────────────────────────────────── */

static void on_signal(int sig) {
    int e = errno;
    unsigned char c = (unsigned char)sig;
    (void)!write(sig_pipe[1], &c, 1);
    errno = e;
}

static void write_all(int fd, const char *p, size_t n) {
    while (n > 0) {
        ssize_t w = write(fd, p, n);
        if (w < 0) {
            if (errno == EINTR) continue;
            if (errno == EAGAIN) { struct pollfd q = {fd, POLLOUT, 0}; poll(&q, 1, 100); continue; }
            return;
        }
        p += w; n -= (size_t)w;
    }
}

static void raw_mode(void) {
    if (!have_tio) return;
    struct termios t = saved_tio;
    cfmakeraw(&t);
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &t);
}

static void restore_mode(void) {
    if (have_tio) tcsetattr(STDIN_FILENO, TCSAFLUSH, &saved_tio);
}

static void sync_winsize(void) {
    struct winsize ws;
    if (ioctl(STDIN_FILENO, TIOCGWINSZ, &ws) == 0) ioctl(master_fd, TIOCSWINSZ, &ws);
}

/* ── worker: applies state changes to tmux, one at a time ────────────────── */

static void run(char *const argv[]) {
    pid_t p = fork();
    if (p == 0) { execvp(argv[0], argv); _exit(127); }
    if (p > 0) while (waitpid(p, NULL, 0) < 0 && errno == EINTR) {}
}

static void worker_loop(int fd) {
    const char *home = getenv("HOME");
    const char *pane = getenv("TMUX_PANE");
    char agent_state[1024];
    snprintf(agent_state, sizeof agent_state, "%s/.local/bin/agent-state", home ? home : "");
    FILE *in = fdopen(fd, "r");
    char line[256];
    while (in && fgets(line, sizeof line, in)) {
        line[strcspn(line, "\n")] = 0;
        if (strncmp(line, "state ", 6) == 0) {
            char *argv[] = {agent_state, line + 6, NULL};
            run(argv);
        } else if (strncmp(line, "subagents ", 10) == 0 && pane) {
            char *n = line + 10;
            if (strcmp(n, "0") == 0) {
                char *argv[] = {"tmux", "set-option", "-wu", "-t", (char *)pane, "@agent_subagents", NULL};
                run(argv);
            } else {
                char *argv[] = {"tmux", "set-option", "-w", "-t", (char *)pane, "@agent_subagents", n, NULL};
                run(argv);
            }
        }
    }
    _exit(0);
}

static void start_worker(void) {
    int p[2];
    if (pipe(p) < 0) return;
    pid_t w = fork();
    if (w < 0) { close(p[0]); close(p[1]); return; }
    if (w == 0) {
        close(p[1]);
        int null = open("/dev/null", O_RDWR);
        if (null >= 0) { dup2(null, 0); dup2(null, 1); dup2(null, 2); }
        signal(SIGPIPE, SIG_DFL);
        worker_loop(p[0]);
    }
    close(p[0]);
    worker_fd = p[1];
    fcntl(worker_fd, F_SETFD, FD_CLOEXEC);
}

static void tell_worker(const char *fmt, const char *arg) {
    if (worker_fd < 0) return;
    char buf[128];
    int n = snprintf(buf, sizeof buf, fmt, arg);
    if (n > 0) write_all(worker_fd, buf, (size_t)n);
}

/* ── program status records ──────────────────────────────────────────────── */

enum st { ST_NONE, ST_IDLE, ST_WORKING, ST_BLOCKED, ST_DONE, ST_ERROR };

static enum st root = ST_NONE;
static int had_turn;
static struct { char id[129]; enum st st; } kids[MAX_CHILDREN];
static int nkids;
static const char *sent_dot = "";
static int sent_subs = -1;

static int parse_state(const char *v, enum st *out) {
    static const struct { const char *name; enum st st; } map[] = {
        {"idle", ST_IDLE}, {"working", ST_WORKING}, {"blocked", ST_BLOCKED},
        {"done", ST_DONE}, {"error", ST_ERROR}, {"clear", ST_NONE}};
    for (size_t i = 0; i < sizeof map / sizeof *map; i++)
        if (strcmp(v, map[i].name) == 0) { *out = map[i].st; return 1; }
    return 0;
}

/* id is `prefix` itself or a descendant of it ("a" covers "a/b"). */
static int under(const char *id, const char *prefix) {
    size_t n = strlen(prefix);
    return strncmp(id, prefix, n) == 0 && (id[n] == 0 || id[n] == '/');
}

static void publish(void) {
    int blocked = root == ST_BLOCKED || root == ST_ERROR, live = 0;
    for (int i = 0; i < nkids; i++) {
        if (kids[i].st == ST_BLOCKED) blocked = 1;
        if (kids[i].st == ST_WORKING || kids[i].st == ST_BLOCKED) live++;
    }
    const char *dot;
    if (blocked) dot = "needs-input";
    else if (root == ST_WORKING || live) dot = "running";
    else if (root == ST_DONE) dot = "done";
    else if (root == ST_IDLE && had_turn) dot = "idle";
    else dot = "none";

    if (strcmp(dot, sent_dot) != 0) { tell_worker("state %s\n", dot); sent_dot = dot; }
    if (live != sent_subs) {
        char n[16];
        snprintf(n, sizeof n, "%d", live);
        tell_worker("subagents %s\n", n);
        sent_subs = live;
    }
}

static void handle_report(char *body) {
    char *state = NULL, *id = NULL;
    for (char *kv = strtok(body, ":"); kv; kv = strtok(NULL, ":")) {
        char *eq = strchr(kv, '=');
        if (!eq) continue;
        *eq = 0;
        if (strcmp(kv, "state") == 0) state = eq + 1;
        else if (strcmp(kv, "id") == 0) id = eq + 1;
    }
    enum st st;
    if (!state || !parse_state(state, &st)) return; /* unknown state: ignore the report */
    if (id && (*id == 0 || strlen(id) > 128)) return;
    int clear = strcmp(state, "clear") == 0;

    if (!id) {
        if (clear) { root = ST_NONE; nkids = 0; had_turn = 0; }
        else {
            root = st;
            if (st != ST_IDLE) had_turn = 1;
        }
    } else if (clear) {
        int j = 0;
        for (int i = 0; i < nkids; i++) if (!under(kids[i].id, id)) kids[j++] = kids[i];
        nkids = j;
    } else {
        int i;
        for (i = 0; i < nkids && strcmp(kids[i].id, id) != 0; i++) {}
        if (i == nkids) {
            if (nkids == MAX_CHILDREN) { /* full: evict the oldest, as the spec allows */
                memmove(&kids[0], &kids[1], sizeof kids[0] * (MAX_CHILDREN - 1));
                i = --nkids;
            }
            nkids++;
            snprintf(kids[i].id, sizeof kids[i].id, "%s", id);
        }
        kids[i].st = st;
    }
    publish();
}

/* ── output filter: strip OSC 7501, answer the probe ─────────────────────── */

/* Bytes held back while they might still turn into "\e]7501;": the matched
 * prefix (match > 0), or a report body being collected (in_body). */
static int match, in_body, body_esc;
static char body[BODY_MAX + 1];
static size_t body_len;

static void finish_body(void) {
    body[body_len] = 0;
    if (strcmp(body, "?") == 0) write_all(master_fd, "\033]7501;?\033\\", 11);
    else handle_report(body);
    in_body = body_esc = 0;
    body_len = 0;
}

static void filter(const char *in, size_t n) {
    char out[65536 + PREFIX_LEN];
    size_t o = 0;
    for (size_t i = 0; i < n; i++) {
        char c = in[i];
        if (in_body) {
            if (body_esc) {
                if (c == '\\') { finish_body(); continue; }
                in_body = body_esc = 0; body_len = 0; /* malformed: drop it */
            } else if (c == '\a') { finish_body(); continue; }
            else if (c == '\033') { body_esc = 1; continue; }
            else if (body_len < BODY_MAX) { body[body_len++] = c; continue; }
            else { in_body = 0; body_len = 0; continue; } /* over the limit: drop it */
        }
        if (c == PREFIX[match]) {
            if (++match == PREFIX_LEN) { match = 0; in_body = 1; }
            continue;
        }
        if (match) { /* false start: release what was held, then rescan c */
            memcpy(out + o, PREFIX, (size_t)match);
            o += (size_t)match;
            match = 0;
            if (c == PREFIX[0]) { match = 1; continue; }
        }
        out[o++] = c;
    }
    if (o) write_all(STDOUT_FILENO, out, o);
}

/* A held prefix with nothing following it for a moment is just output (a lone
 * ESC, say) — let it through rather than sit on it until the next write. */
static void flush_held(void) {
    if (match && !in_body) { write_all(STDOUT_FILENO, PREFIX, (size_t)match); match = 0; }
}

/* ── job control inside the pty ──────────────────────────────────────────── */

/* forkpty's child leads a new session, and a session leader's process group is
 * orphaned: the kernel discards the SIGTSTP a program sends itself there, so
 * Claude's Ctrl+Z printed "suspended" and kept running. A shell solves this by
 * running jobs in their own group under it, and so does this: the program runs
 * in a foreground group of its own, and when it stops, this process stops too
 * (SIGSTOP always lands), which the outer loop sees as its child stopping. */
static pid_t job;

static void forward_to_job(int sig) { kill(-job, sig); }

static void job_control(char **cmd) {
    signal(SIGTTOU, SIG_IGN); /* tcsetpgrp from a background group */
    job = fork();
    if (job < 0) _exit(127);
    if (job == 0) {
        setpgid(0, 0);
        tcsetpgrp(STDIN_FILENO, getpid());
        signal(SIGTTOU, SIG_DFL);
        execvp(cmd[0], cmd);
        perror(cmd[0]);
        _exit(127);
    }
    setpgid(job, job);
    tcsetpgrp(STDIN_FILENO, job);
    int fwd[] = {SIGHUP, SIGTERM, SIGINT, SIGQUIT};
    for (size_t i = 0; i < sizeof fwd / sizeof *fwd; i++) signal(fwd[i], forward_to_job);
    for (;;) {
        int st;
        if (waitpid(job, &st, WUNTRACED) < 0) {
            if (errno == EINTR) continue;
            _exit(1);
        }
        if (WIFSTOPPED(st)) {
            kill(getpid(), SIGSTOP); /* … until the outer loop sends SIGCONT */
            tcsetpgrp(STDIN_FILENO, job);
            kill(-job, SIGCONT);
        } else if (WIFEXITED(st)) {
            _exit(WEXITSTATUS(st));
        } else if (WIFSIGNALED(st)) {
            _exit(128 + WTERMSIG(st));
        }
    }
}

/* ── main ────────────────────────────────────────────────────────────────── */

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: agent-pty <command> [args...]\n");
        return 2;
    }
    /* Not on a terminal (piped, redirected): nothing to sit between. */
    if (!isatty(STDIN_FILENO) || !isatty(STDOUT_FILENO)) {
        execvp(argv[1], argv + 1);
        perror(argv[1]);
        return 127;
    }

    have_tio = tcgetattr(STDIN_FILENO, &saved_tio) == 0;
    struct winsize ws;
    int have_ws = ioctl(STDIN_FILENO, TIOCGWINSZ, &ws) == 0;

    start_worker();

    child = forkpty(&master_fd, NULL, have_tio ? &saved_tio : NULL, have_ws ? &ws : NULL);
    if (child < 0) { perror("forkpty"); return 1; }
    if (child == 0) job_control(argv + 1);

    if (pipe(sig_pipe) < 0) return 1;
    fcntl(sig_pipe[0], F_SETFL, O_NONBLOCK);
    fcntl(sig_pipe[1], F_SETFL, O_NONBLOCK);
    struct sigaction sa;
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = on_signal;
    sigemptyset(&sa.sa_mask);
    int sigs[] = {SIGWINCH, SIGCHLD, SIGHUP, SIGTERM, SIGINT, SIGQUIT};
    for (size_t i = 0; i < sizeof sigs / sizeof *sigs; i++) sigaction(sigs[i], &sa, NULL);
    signal(SIGPIPE, SIG_IGN);

    raw_mode();

    char buf[65536];
    int status = 0, done = 0;
    while (!done) {
        struct pollfd fds[3] = {
            {STDIN_FILENO, POLLIN, 0}, {master_fd, POLLIN, 0}, {sig_pipe[0], POLLIN, 0}};
        int r = poll(fds, 3, match ? 30 : -1);
        if (r < 0) { if (errno == EINTR) continue; break; }
        if (r == 0) { flush_held(); continue; }

        if (fds[2].revents & POLLIN) {
            unsigned char s;
            while (read(sig_pipe[0], &s, 1) == 1) {
                if (s == SIGWINCH) sync_winsize(); /* the pty signals its foreground group */
                else if (s == SIGCHLD) {
                    pid_t p;
                    while ((p = waitpid(child, &status, WNOHANG | WUNTRACED)) > 0) {
                        if (WIFSTOPPED(status)) {
                            /* The program suspended itself (Ctrl+Z): suspend us
                             * too, so the shell gets its prompt back, and pass
                             * the continue on when `fg` wakes us. */
                            restore_mode();
                            kill(getpid(), SIGSTOP);
                            raw_mode();
                            sync_winsize();
                            kill(child, SIGCONT);
                        } else if (WIFEXITED(status) || WIFSIGNALED(status)) {
                            done = 1;
                        }
                    }
                } else {
                    kill(child, s); /* HUP/TERM/INT/QUIT: the program decides */
                }
            }
        }
        if (fds[1].revents & (POLLIN | POLLHUP | POLLERR)) {
            ssize_t n = read(master_fd, buf, sizeof buf);
            if (n > 0) filter(buf, (size_t)n);
            else if (n == 0 || (errno != EINTR && errno != EAGAIN)) {
                /* slave side closed: the program is gone or going */
                if (!done) { while (waitpid(child, &status, 0) < 0 && errno == EINTR) {} done = 1; }
            }
        }
        if (!done && (fds[0].revents & POLLIN)) {
            ssize_t n = read(STDIN_FILENO, buf, sizeof buf);
            if (n > 0) write_all(master_fd, buf, (size_t)n);
        }
    }

    /* Drain whatever the program printed on its way out. */
    fcntl(master_fd, F_SETFL, O_NONBLOCK);
    for (ssize_t n; (n = read(master_fd, buf, sizeof buf)) > 0;) filter(buf, (size_t)n);
    flush_held();
    restore_mode();

    root = ST_NONE; nkids = 0; had_turn = 0;
    publish();
    if (worker_fd >= 0) close(worker_fd); /* the worker finishes its queue, then exits */

    if (WIFEXITED(status)) return WEXITSTATUS(status);
    if (WIFSIGNALED(status)) return 128 + WTERMSIG(status);
    return 1;
}
