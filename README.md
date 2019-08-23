# Hubot Terms

A glossary for Hubot, forked from a factoids implementation (therealklanni/hubot-factoids)[https://github.com/therealklanni/hubot-factoids].

## Features

* @mention support: definition will be directed at mentioned user.
* Customizable prefix
* Aliases: point a definition at the value of another definition.
* Substitutive editing using sed-like syntax.
* Term history: any time a new value is set on a term, the name of the
user, current date, previous value and new value are recorded
* Term popularity: currently only visible in the raw data
* HTTP route to view raw JSON data.

## Installation

`npm install hubot-terminator`

## Configuration

none

## Commands

### Create/update a definition

Creates a new definition if it doesn't exist, or overwrites the definition value with
the new value. Definitions maintain a history of all past values along with who updated
the value and when.

> **Note:** `<Term>` can be any string which does not contain `=` or `=~`
(these reserved characters delimit the definition and its value), although special
characters should be avoided.

`hubot: learn <term> = <definition>`

### Inline editing a definition

If you prefer, you can edit a definition value inline, using a sed-like substitution
expression.

`hubot: learn <term> =~ s/expression/replace/gi`

`hubot: learn <term> =~ s/expression/replace/i`

`hubot: learn <term> =~ s/expression/replace/g`

`hubot: learn <term> =~ s/expression/replace/`

### Set an alias

An alias will point to the specified pre-existing definition and when invoked will
return that term's definition.

`hubot: alias <term> = <definition>`

### Forget a definition

Disables responding to a definition. The definition is not deleted from memory, and
can be re-enabled by setting a new value (its complete history is retained).

`hubot: forget <term>`

### Get all definitions

Responds with the raw data output of the definition data

`hubot: list all definitions`

### Recall a definition

Recall the value of the given definition.

> **Note:** Hubot need not be directly addressed.

`wtf is <term>`

Can be combined with a @mention to direct the message at another user:

`wtf is <term> @user`

Hubot will respond accordingly:

`Hubot> @user: term: definition`

### Search for a definition

Find a definition containing the given string. The string can be matched in either
the term or definition.

`hubot: search foobar`


### Drop a definition

**Permanently removes a definition — this action cannot be undone.**
If [hubot-auth](https://github.com/hubot-scripts/hubot-auth) script is loaded,
"admin" or "terminator-admin" role is required to perform this action. It's
recommended you use the `forget` command instead of `drop`.

`hubot: drop <term>`
