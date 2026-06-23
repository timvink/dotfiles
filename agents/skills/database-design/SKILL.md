---
name: database-design
description: |
  Vetted patterns for modeling data in relational databases. Use when designing
  a schema, modeling many content/entity types that share common metadata, or
  choosing between inheritance and polymorphism approaches (STI, MTI, polymorphic
  associations, delegated types). Framework-agnostic, with notes for Rails, Django,
  and SQLAlchemy. First pattern: the Rails delegated type (recordings/recordables).
---

# Database Design Patterns

A catalog of patterns for modeling data in relational databases. Each entry says
**when to reach for it** and the trade-offs. Pick the pattern that matches the
shape of the problem — don't apply one by default.

## Patterns

### 1. Delegated Type (Recordings / Recordables)

**Use when:** you have many *kinds* of content (messages, documents, uploads,
events, …) that all share the same metadata and lifecycle — creator, timestamps,
status/archived, position in a hierarchy — but each kind has its own unique
columns, and you want to manage them **uniformly** (one activity timeline, one
search index, generic archive/copy/trash actions).

**The idea — split into two layers:**

- A narrow **parent** table (`recordings`) holds *only* shared metadata plus a
  polymorphic pointer (`recordable_type`, `recordable_id`). No content columns.
- Separate **child** tables (`recordables`: `messages`, `documents`, `uploads`, …)
  hold *only* the columns unique to that type. No timestamps or shared metadata.
- The parent **delegates** type-specific calls down to the child it points at.

This is an **inversion of a normal polymorphic association**: instead of each
child pointing back to a parent, one parent table can point at *any* child type.
That inversion is what makes top-down queries ("recent activity across all types")
a single indexed scan of the narrow `recordings` table.

**Schema sketch:**

```
recordings                          messages           uploads
----------                          --------           -------
id            (pk)                  id  (pk)            id  (pk)
recordable_type  ─┐                 subject            filename
recordable_id    ─┘ points at →     body               byte_size
creator_id                                              content_type
bucket_id      (container)
parent_id      (tree)
status, position, created_at, …
```

**Rails (canonical — `delegated_type`, AR 6.1+):**

```ruby
class Recording < ApplicationRecord
  delegated_type :recordable, types: %w[ Message Document Upload ], dependent: :destroy
  delegate :title, to: :recordable          # forward shared interface down
end

module Recordable                            # mixed into every child
  extend ActiveSupport::Concern
  included do
    has_one :recording, as: :recordable, touch: true
  end
end

class Message < ApplicationRecord
  include Recordable
  def title = subject
end
```

Gives you `recording.message`, `Recording.messages`, `bucket.recordings.documents`,
and polymorphic creation. (Basecamp's internal gem spells the macro
`has_delegated_type`; Rails core ships it as `delegated_type`.)

**Python equivalents** (no first-class macro — you wire it by hand):

- **Django:** model `Recording` with `content_type` (FK to `ContentType`),
  `object_id`, and `recordable = GenericForeignKey("content_type", "object_id")`;
  give each child a `GenericRelation(Recording)`. This is the deliberate,
  optimized form of the `contenttypes` framework. Django's **Multi-Table
  Inheritance** produces a similar parent+`OneToOne`-children layout automatically,
  but its implicit joins are rigid and can hurt at scale.
- **SQLAlchemy:** closest built-in is **joined-table inheritance**, but the
  delegated-type spirit is *composition over inheritance* — see the official
  "generic associations" recipe (parent holds `recordable_type`/`recordable_id`,
  children expose a back-association) rather than subclassing a base model.

**Benefits:**

- **Zero-friction migrations.** New content type = new small table + class. The
  huge `recordings` table is never touched; archive/search/timeline "just work."
- **Cheap copy.** Treat recordables as immutable: copying = a new `recordings`
  row pointing at the *same* recordable id. No content duplication. (Edits =
  new recordable + repointed recording, which also gives you version history.)
- **Unified timeline & search.** One indexed query over `recordings` instead of
  `UNION`-ing every child table.
- **Generic controllers & caching.** One code path archives/trashes/moves any
  type; cache + invalidate on the recording. Children declare capabilities via
  predicates (`commentable?`, `copyable?`).

**Trade-offs:**

- An extra join to load actual content (preload/eager-load to avoid N+1).
- Child models look thin — behavior lives in the parent's generic methods, which
  is a learning curve.
- When a child needs to know about its container (e.g. a comment deriving a title
  from its parent), pass the recording in as context.

**Links:**

- 37signals write-up — https://dev.37signals.com/the-rails-delegated-type-pattern/
- Rails guide (`delegated_type`) — https://guides.rubyonrails.org/association_basics.html#delegated-types
- API docs — https://api.rubyonrails.org/classes/ActiveRecord/DelegatedType.html
- Django GenericForeignKey — https://docs.djangoproject.com/en/stable/ref/contrib/contenttypes/
- SQLAlchemy generic associations — https://docs.sqlalchemy.org/en/20/_modules/examples/generic_associations/

---

#### How it compares

| | STI (single table) | MTI / joined | Polymorphic assoc. | **Delegated type** |
|---|---|---|---|---|
| Layout | one wide table + `type` col | base table + child tables (inheritance) | child points to any parent | **parent points to any child** |
| New type cost | add columns to the hot table | new child table (rigid joins) | low | **new small table, core untouched** |
| Top-down query | trivial but table is wide/NULL-heavy | joins per type | hard (must hit each table) | **one scan of narrow parent** |
| Best when | few types, mostly shared cols | strict is-a hierarchy | child genuinely belongs to varied owners | **many types, shared lifecycle, uniform mgmt** |
