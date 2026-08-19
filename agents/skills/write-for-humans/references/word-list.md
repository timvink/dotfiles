# Word list (curated)

Entries copied verbatim from the [Google developer documentation style guide
word list](https://developers.google.com/style/word-list), trimmed to the terms
that matter in general writing. Google-product-specific entries are left out —
check the full list online when a term isn't here.

Two strengths of guidance, in Google's own terms: **"Don't use"** means avoid the
term in all cases (ambiguous, or an offensive or non-inclusive association).
**"Avoid"** or "use with caution" means prefer something else where you can, but
the term is available if you need it.

Content licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

## Plain words instead of inflated ones

### utilize, utilization

Use with caution. Don't use _utilize_ when you mean _use_. It's OK to use _utilize_ or _utilization_ when referring to the quantity of a resource being used. 

Recommended: When CPU utilization exceeds 75%, the autoscaler adds more CPU resources. 

Recommended: To distribute network traffic, use a load balancer. 

Not recommended: To distribute network traffic, utilize a load balancer.

### leverage

Avoid using if you mean _use_. If possible, use a more precise term. For example, _use_, _build on_, or _take advantage of_.

### in order to

Avoid _in order to_; instead, use _to_.

Use _in order to_ when needed to clarify meaning or to make something easier to read. 

Recommended: You can use monitoring to help identify issues. 

Not recommended: You can use monitoring in order to help identify issues. 

Recommended: The infrastructure is required in order to support search. 

Not recommended: The infrastructure is required to support search.

### comprise

Don't use. Instead, use _consist of_, _contain_, or _include_.

### execute

Verb commonly used to refer to function calls, SQL queries, and other processes. When the meaning is the same, use the simpler word _run_ instead. If you need to use a more precise term for your context, use that term.

### terminate

Avoid using as a synonym for _stop_. Instead, use words like _stop_, _exit_, _cancel_, or _end_. 

For a specific context where you can use _terminate_ as a synonym for _stop_, see [Documenting command-line syntax](https://developers.google.com/style/code-syntax#linux-signals). 

In some contexts, such as telephony and networking, _terminate_ has specific technical meanings that aren't synonyms for _stop_; in those contexts, you can use _terminate_.

### ingest

Use _import_, _load_, or _copy_ when referring to simple movement of data. Use _ingest_ only when referring to such operations that also involve significant processing of the data.

### desire, desired

Don't use. Instead, use a word like _want_ or _need_.

Recommended: Set the value to the size that you want. 

Not recommended: Set the value to the size that you desire. 

Not recommended: Set the value to the desired size.

### wish

Don't use. Instead, use a word like _want_ or _need_.

### via

Don't use.

### workload

The term _workload_ might refer to software, like an app or a service; to app resources, like data and infrastructure; or to physical components that work together. 

Where possible, use a more precise term to describe what you mean. If you use the term _workload_, define your meaning on first use as you normally would with jargon and other ambiguous terms.

### native

Avoid using _native_ to refer to people.

When referring to software products, try to use a more precise term—for example, use _built-in_ to describe a feature that's part of a product. 

The term _native_ isn't necessarily clear—for example, _cloud-native_ could mean that something was written for the cloud, or that it's built in to a cloud platform, or that it currently exists in a cloud platform. 

Alternatives to a term like _cloud-native_ could include: _modern cloud_, _born in the cloud_, _cloud first_, and _cloud-born_.

### first class, first-class, first-class citizen

Don't use _first class_ or _first-class citizen_. Instead, use another term that's appropriate for the context, such as _higher-order_, _anonymous_, or _nested_, or loosely describe the specific characteristics or features of the entity, resource, language, or framework. 

Recommended: These widgets have full access to the event system and lifecycle hooks. 

Not recommended: The widgets are first-class components in the UI framework. 

Recommended: Virtual machines are higher-order resources that can participate in resource groups and are integrated in a variety of identity, networking, and storage services. 

Not recommended: Virtual machines are treated as first-class resources across the identity, networking, and storage services. 

For more information, see [Write inclusive documentation](https://developers.google.com/style/inclusive-documentation).

### cons

Don't use. Instead, use a more precise term, such as _disadvantages_.

### pros

Don't use. Instead, use a more precise term, such as _advantages_.

## Words that are ambiguous or translate badly

### as

If you mean _because_, then use _because_ instead of _as_. _As_ is ambiguous; it can refer to the passage of time. _Because_ refers to causation or the reason for something.

### since

If you mean _because_, then use _because_ instead of _since_. _Since_ is ambiguous; it can refer to the passage of time. _Because_ refers to causation or the reason for something.

### while

Don't use to indicate a contrast. Instead, use a more precise term, such as _although_. 

OK to use to refer to a period of time.

### once

If you mean _after_, then use _after_ instead of _once_.

### then

Although it is common in casual usage to omit the word _then_ in _if...then_statements, you should include helper words like _then_ in technical documentation. For more information, see [Use clear, precise, and unambiguous language](https://developers.google.com/style/translation#clear-language).

### later

Use for a range of version numbers, not _higher_.

Recommended: Use version 2.2 or later. 

Not recommended: Use version 2.2 or higher. 

Not recommended: Use version 2.2+. 

A release with the highest version number might not be the latest version. For example, if version 2.0 of an operating system receives a bug-fix update after version 3.0 has been released, then version 2.0.1 might be the latest version, even though its version number is lower than 3.0\. 

In Android documentation, don't use _later_ for a range of version numbers. Instead, use _higher_. 

When referring to a position in a document, use _later_ or _following_, not _below_.

### above

Don't use for a range of version numbers. Instead, use [_later_](https://developers.google.com/style/word-list#later). 

Don't use to refer to a position in a document. Instead, use _earlier_ or _preceding_. 

Don't use to refer to a position in the UI. Instead, write instructions that avoid directional language. For more information, see [Writing accessible documentation](https://developers.google.com/style/accessibility). 

It's OK to use _above_ in a non-directional way, such as when describing a hierarchy.

### below

Don't use for a range of version numbers. Instead, use [_earlier_](https://developers.google.com/style/word-list#earlier). 

Don't use to refer to a position in a document. Instead, use _later_or _following_. 

Don't use to refer to a position in the UI. Instead, write instructions that avoid directional language. For more information, see [Writing accessible documentation](https://developers.google.com/style/accessibility). 

It's OK to use _below_ in set phrases such as _below (the) average_, _below the mean_, _below zero_. 

It's OK to use _below_ in a non-directional way, such as when describing a hierarchy.

### and/or

Don't use unless space is limited, such as in a table. For more information, see [Slashes](https://developers.google.com/style/slashes#and-or).

### aka

Don't use. Instead, write out _also known as_, or present an alternative term using parentheses or the word _or_. You can also write out a definition. 

Recommended: Geographic data, also known as geospatial data, is ... 

Recommended: Geographic data (geospatial data) is ... 

Recommended: Geographic data, or geospatial data, is ...

### e.g.

Don't use. Instead, use phrases like _for example_ or _such as_. Many people confuse _e.g._ and _i.e._

### etc.

Avoid using _etc._, _and so forth_, and _and so on_wherever possible. If you really need to use one, use _etc._Always include the period, even if a comma follows immediately after. 

Recommended: Your app might experience problems such as instability or high latency. 

Recommended: Your app might experience problems, including instability or high latency. 

Not recommended: Your app might experience instability, high latency, and so on. 

Not recommended: Your app might experience instability, high latency, etc. 

Not recommended: If your app experiences instability, high latency, etc., follow these steps:

### like

It's OK to use _like_ for either drawing comparisons (in the sense of _similar to_) or introducing examples (in the sense of _such as_). 

Recommended: Common I/O operations, like reading files or making network requests, can be asynchronous. 

Recommended: The new compression algorithm works like a dictionary encoder, replacing repeated strings with shorter codes. 

See also [such as](https://developers.google.com/style/word-list#such-as). For more information, see [Format examples](https://developers.google.com/style/format-examples).

## Filler, hedging, and false reassurance

### please

Don't use _please_ in the normal course of explaining how to use a product, even if you're explaining a difficult task. 

Don't use the phrase _please note_.

Use _please_ only when you're asking for permission or forgiveness—for example, when what you're asking for benefits you, inconveniences a reader, or suggests a potential issue with a product. 

Recommended: If the issue persists, please contact your account representative. 

For more information, see [voice and tone](https://developers.google.com/style/tone#politeness).

### just

Avoid. Usually, _just_ is a filler word that you can delete without affecting your meaning. 

Recommended: BigQuery skips the row. 

Not recommended: BigQuery just skips the row. 

If your meaning is unclear without _just_, then use a more specific term such as _only_, _instead_, or _previously_, or revise your language to be more specific. (Even if one of these replacement terms fits, you often don't need it.) 

Recommended: You can run DML statements in the same way that you'd run a `SELECT`statement. 

Not recommended: You can run DML statements just as you'd run a `SELECT` statement. 

Recommended: Let a user query only the table without full dataset access. 

Recommended: Let a user query the table without full dataset access. 

Not recommended: Let a user query just the table without full dataset access. 

Sometimes, _just_ is useful for conveying that one approach is simpler than another. In those cases, use _just_ instead of [_simply_](https://developers.google.com/style/word-list#simple). 

Recommended: Use the namespace ID `namespace:example-kind` or just `example-kind`.

### simple, simply

What might be simple for you might not be simple for others. Try eliminating this word from the sentence because usually the same meaning can be conveyed without it.

### easy, easily

What might be easy for you might not be easy for others. Try eliminating this word from the sentence because usually the same meaning can be conveyed without it.

### quick, quickly

What might be quick for you might not be quick for others. Try eliminating this word from the sentence because usually the same meaning can be conveyed without it.

### allows you to

Don't use. Instead, use _lets you_. For more information, see [enable](https://developers.google.com/style/word-list#enable).

### can

Use _can_ in the following ways:

* To convey permission or ability (for example, "You can access the server").
* To refer to an optional action (for example, "You can also view logs with the Log Viewer").
* To describe a possible outcome (for example, "The process can take 30 minutes").

See also [could](https://developers.google.com/style/word-list#could), [may](https://developers.google.com/style/word-list#may), [might](https://developers.google.com/style/word-list#might), [must](https://developers.google.com/style/word-list#must), [should](https://developers.google.com/style/word-list#should), and [would](https://developers.google.com/style/word-list#would). 

For information about clarifying who's performing an action, see [Active voice](https://developers.google.com/style/voice).

### may

In general, reserve for official policy or legal considerations.

To convey _possibility_, use _can_ or _might_instead. 

To convey _permission_, use _can_ instead. 

See also [can](https://developers.google.com/style/word-list#can), [could](https://developers.google.com/style/word-list#could), [might](https://developers.google.com/style/word-list#might), [must](https://developers.google.com/style/word-list#must), [should](https://developers.google.com/style/word-list#should), and [would](https://developers.google.com/style/word-list#would). 

For information about clarifying who's performing an action, see [Active voice](https://developers.google.com/style/voice).

### might

Use to convey possibility or an uncertain outcome (for example, "You might be prompted to enter your credentials"). 

See also [can](https://developers.google.com/style/word-list#can), [could](https://developers.google.com/style/word-list#could), [may](https://developers.google.com/style/word-list#may), [must](https://developers.google.com/style/word-list#must), [should](https://developers.google.com/style/word-list#should), and [would](https://developers.google.com/style/word-list#would). 

For information about clarifying who's performing an action, see [Active voice](https://developers.google.com/style/voice).

### must

Use to describe a required action or state (for example, "You must have the Editor role"). You can also write _you need_ in order to convey a requirement. 

See also [can](https://developers.google.com/style/word-list#can), [could](https://developers.google.com/style/word-list#could), [may](https://developers.google.com/style/word-list#may), [might](https://developers.google.com/style/word-list#might), [should](https://developers.google.com/style/word-list#should), and [would](https://developers.google.com/style/word-list#would). 

For information about clarifying who's performing an action, see [Active voice](https://developers.google.com/style/voice).

### shall

Avoid _shall_ except under advice from a lawyer. For more information, see [should](https://developers.google.com/style/word-list#should).

### should, should be

Generally avoid.

Because _should_ is ambiguous by definition, it can be problematic. For more information and alternatives, see [Word choice for recommendations and requirements](https://developers.google.com/style/prescriptive-documentation#word-choice). 

See also [can](https://developers.google.com/style/word-list#can), [could](https://developers.google.com/style/word-list#could), [may](https://developers.google.com/style/word-list#may), [might](https://developers.google.com/style/word-list#might), [must](https://developers.google.com/style/word-list#must), and [would](https://developers.google.com/style/word-list#would).

### currently

Avoid because this word is implied. The word can also prematurely disclose product or feature strategy or inappropriately imply that a product or feature might change. 

See also [as of this writing](https://developers.google.com/style/word-list#as-of-this-writing) and [presently](https://developers.google.com/style/word-list#presently). 

Recommended: Windows isn't supported. 

Not recommended: Windows isn't currently supported. 

For more information, see [Timeless documentation](https://developers.google.com/style/timeless-documentation).

### see

OK as a general term and when referring to links and cross-references. Our research indicates that language relating to sight is OK for a wide range of readers. For more information, see [Cross-references and linking](https://developers.google.com/style/cross-references).

### check

Don't use to refer to marking a checkbox. Instead, use _select_. 

Recommended: Select **Automatically check for updates**. 

Not recommended: Check **Automatically check for updates**.

## Violent, ableist, or non-inclusive terms

### abort

Avoid in general usage. Instead, use words like _stop_, _exit_, _cancel_, or _end_. In Linux, _abort_ refers to a type of signal that terminates an abnormal process.

### kill

Avoid when possible. Instead, use words like _stop_, _exit_, _cancel_, or _end_. For exceptions to this rule, see [Documenting command-line syntax](https://developers.google.com/style/code-syntax#linux-signals).

### hang, hung

Don't use to refer to a computer or system that is not responding. Instead, use _stop responding_ or _not responding_. For more information, see [Avoid figurative language](https://developers.google.com/style/inclusive-documentation#figurative-language).

### blacklist, black list, black-list

Don't use _blacklist_, _whitelist_, and _graylist_. Instead, use more precise terms that are appropriate for your domain. 

* For the noun _blacklist_, consider using a replacement such as _denylist_, _excludelist_, or _blocklist_.
* For the noun _whitelist_, consider using a replacement such as _allowlist_, _trustlist_, or _safelist_.
* For the noun _graylist_ (_greylist_), consider using a replacement such as _provisional list_.

In all of these cases, consider that there might not actually be a list involved. When replacing problematic terms, be sure to be technically accurate for the specific context. 

For the verb forms of these words, a simple word-for-word replacement typically isn't the best solution. Instead, replace verbs such as _blacklisted_ with phrases that accurately convey the relevant action. For example: 

Recommended: To deny requests from an IP address, add it to the `dos.yaml` file. 

Not recommended: To denylist an IP address, add it to the `dos.yaml` file. 

Don't use: To blacklist an IP address, add it to the `dos.yaml` file. 

If the command or code that you're documenting uses one of these words, then use the words only in direct reference to the code items ([formatted as code](https://developers.google.com/style/code-in-text)), and make it clear what you're referring to. 

Recommended: Add a user to the allowlist (`whitelist`) by entering the following: `whitelist adduser EMAIL_ADDRESS`. 

Not recommended: Add a user to the whitelist by entering the following: `whitelist adduser EMAIL_ADDRESS`. 

For more information, see the [inclusive documentation](https://developers.google.com/style/inclusive-documentation) page.

### whitelist, white list, white-list

Don't use. See [blacklist](https://developers.google.com/style/word-list#blacklist).

### allowlist (verb), allowlisted, allowlisting

Don't use as a verb. Instead, rewrite to improve clarity.

OK to use _allowlist_ as a noun.

For more information, see [blacklist](https://developers.google.com/style/word-list#blacklist).

### master

Use with caution. Never use in conjunction with _slave_. Where possible, replace _master_ with a specific term that is accurate for the context, such as _primary_, _main_, _original_, _parent_, _initiator_, _driver_, _controller_, _manager_, _mixer_, _aggregator_, _publisher_, _leader_, or _active_. 

| Guidance                             | Recommended                                                                            | Not recommended                                                                    |  | Don't use _master_ in conjunction with _slave_ in any context. | Cloud SQL primary/replica | Cloud SQL master/slave |
| ------------------------------------ | -------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |  | -------------------------------------------------------------- | ------------------------- | ---------------------- |
| Avoid using _master_ where possible. | GKE control plane Jenkins controller root key (in security) primary key (in databases) | GKE master plane Jenkins master master key (in security) master key (in databases) |  |                                                                |                           |                        |

If the command or code that you're documenting uses the literal word _master_, then use this word only in direct reference to the code item ([formatted as code](https://developers.google.com/style/code-in-text)), make it clear what you're referring to, and use the new term thereafter. 

See also [_slave_](https://developers.google.com/style/word-list#slave).

### slave

Don't use. Instead, use alternative terms appropriate to your domain, such as _worker_ or _replica_. 

If you're replacing the terms _master_ and _slave_ together, then consider such combinations as _primary_/_secondary_, _primary_/_replica_, _original_/_replica_, _controller_/_worker_, _initiator_/_responder_, _mixer_/_leaf_, _aggregator_/_collector_, _publisher_/_subscriber_, _leader_/_follower_, and _active_/_standby_.

If the command or code that you're documenting uses the literal word _slave_, then use this word only in direct reference to the code item ([formatted as code](https://developers.google.com/style/code-in-text)), make it clear what you're referring to, and use the new term thereafter. For example, "Invoke the secondary (`slave`) process directly when debugging issues between the primary and secondary processes."

See also [master](https://developers.google.com/style/word-list#master).

### sanity check

Don't use. Instead, use a term like _quick check_, _confidence check_, _preliminary check_ or _coherence check_.

### crazy, bonkers, mad, lunatic, insane, loony

Don't use. Instead, use _complicated_, _complex_, _baffling_, _strange_, or _unexpected_, and only for inanimate objects.

### blind

Avoid using _blind to_ or _blind eye to_. Instead, use more precise terms like _ignore_, _unaware of_, _disregard_, _avoid_, or _reject_. 

Avoid using _blind writes_. Instead, use a more precise phrase, such as _a write operation without a read operation_. 

Avoid using _blind change_ or _change blindly_. Instead, use a more precise phrase such as _change without first confirming the value_. 

When referring to people, use terms like _person who is blind_, _screen reader user_ (if applicable), _person who is visually impaired_, _person who is low-vision_, _magnification user_(if applicable).

### cripple

Don't use. Instead, use more precise language. For example, instead of _it crippled the server_, write _it slowed the server down_. 

When referring to people, use terms that specifically describe a physical impairment, such as _person with a motor disability_; _person with a mobility impairment_ (refers to walking or moving about); _person with dexterity impairment_ (refers to using a standard mouse or keyboard); _person who uses a wheelchair, walker, or cane_; _wheelchair user_; _person with restricted or limited mobility_.

### dummy variable

Don't use to refer to placeholders. Instead, use _placeholder_. 

Also don't use if referring to the concept in statistics known as a [dummy variable](https://en.wikipedia.org/wiki/Dummy%5Fvariable%5F%28statistics%29). Instead, use alternate terms such as _indicator variable_, _design variable_, _one-hot encoding_, _Boolean indicator_, _binary variable_, or _qualitative variable_.

### grandfather clause, grand-father clause, grand father clause

Don't use. See [grandfathered](https://developers.google.com/style/word-list#grandfathered).

### grandfathered

Don't use to refer to something that is allowed to violate a rule because it predates the rule. Instead, use an adjective like _legacy_ or _exempt_ or a verb like _made an exception_. 

Recommended: The app is exempt because it was released before the new requirements were announced. 

Not recommended: The app is grandfathered in because it was released before the new requirements were announced.

### guys, you guys

When referring to a group of people use non-gendered language, such as _everyone_ or _folks_.

### he, him, his

Don't use a gendered pronoun except for a specific individual of known gender. Use _they_ and _their_ for the general singular pronoun.

### gender-neutral he, him, or his (or she or her)

Don't use. Instead, use the singular _they_ (see [Jane Austen and other famous authors violate what everyone learned in their English class](http://www.pemberley.com/janeinfo/austheir.html)). Don't use _he/she_ or _(s)he_ or other such punctuational approaches. For more information, see [Pronouns](https://developers.google.com/style/pronouns).

### man hours, manhours, man-hours

Avoid using gendered terms. Instead use terms like _person hours_.

### manpower, man power, man-power

Avoid using gendered terms. Instead use terms like _staff_ or _workforce_.

## Who you are talking about

### we

Don't use _we_ (or other first-person plural pronouns such as _our_ or _us_) to address the reader who is performing the tasks that you're documenting. Instead, use _you_. 

It's OK to use _we_ to refer to the organization that's represented as the author of the document as long as the antecedent is clear. For more information, see [Second person and first person](https://developers.google.com/style/person).

### you

Use _you_ instead of [_user_](https://developers.google.com/style/word-list#user) to address the reader of your document. For more information, see [Second person and first person](https://developers.google.com/style/person).

### user

Use the word _user_ only to refer to the user of the software that your reader is developing. Otherwise, address the reader as _you_and assume that they will complete the tasks that you're documenting. For more information, see [Second person and first person](https://developers.google.com/style/person).

## Spellings that trip people up

### email

Not _e-mail_, _Email_, or _E-mail_.

Don't use as a verb.

Use a specific verb in front of the word. For example, _send email_. This construction is better for translation and a [global audience](https://developers.google.com/style/translation).

### internet

Lowercase except at the beginning of a sentence, heading, or list item.

### login (noun or adjective), log in (verb)

For the verb form, _sign in_ is generally better.

If you're documenting a tool that uses the term _log in_, then use that term.

### on-premises

Not _on prem_, _on premise_, or _on-premise_. Hyphenate when used as any part of speech. 

Use to refer to a customer's resources that they manage in their own facilities. Don't use _peer_. 

It can be acceptable to use _on-premises_ as a noun when it would be awkward to repeatedly write out a full phrase like _an on-premises environment_. However, it's preferable to use the more complete phrase whenever possible. 

Recommended: An on-premises database. 

Recommended: The database runs on-premises. 

OK: Moving data from on-premises to Google Cloud.

### setup (noun or adjective), set up (verb)



### read-only

Not _read only_. Always hyphenate _read-only_.

### regex

Don't use. Instead, use _regular expression_.

### ymmv

Don't use. Instead, use something like _Your results might vary_.

### click

When the environment is a desktop with a mouse, use _click_ for most targets, such as buttons, links, list items, and radio buttons. Don't use _click on_. 

Recommended: Click **OK**. 

Not recommended: Click on **OK**. 

Hyphenate _right-click_, _left-click_, and _double-click_. 

When a click or tap action reveals a collapsed list, you can write _click to expand_ or simply _expand_. 

It's OK to write _click in_ when referring to a region that needs focus (for example: _click in the window_), but not when referring to a control or a link. 

For Android apps, don't use _click_. Instead, use [tap](https://developers.google.com/style/word-list#tap).

### drag

Use _drag_, not _click and drag_ and not _drag and drop_. 

OK to use _drag-and-drop_ as an adjective.

Recommended: Drag the USERto the **Authorized** box.

### disable

Don't use _disable_ or _disabled_ to describe something that's broken. 

When describing a user action or the state of a UI element, use a more precise term where possible. You can use _inactive_, _unavailable_, _deactivate_, _turn off_, or _deselect_, depending on the context. Use the same term consistently throughout your document. See also [enable](https://developers.google.com/style/word-list#enable).

### deprecate

To _deprecate_ an item is to recommend against the item's use, typically as a warning that the item will soon be unavailable or unsupported. Don't use _deprecated_ to mean _removed_, _deleted_, _shut down_, or _turned down_.

