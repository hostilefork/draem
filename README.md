![DRAEM logo](https://raw2.github.com/hostilefork/draem/master/draem-logo.png)

**DRAEM** is a static website builder, which is along the lines of something like [Jekyll](http://jekyllrb.com/)...but using open source [Rebol 3](http://en.wikipedia.org/wiki/Rebol).  Blog entries (or pages) are written in a "dialect" of the language, so despite their customized appearance they have no parser of their own.  Rather, they embrace the carefully-chosen limits of the host system to create a [Domain-Specific Language](http://en.wikipedia.org/wiki/Domain-specific_language).

The tool is mostly notable for the reasons Rebol is notable.  This includes depending only on a *half-megabyte*, *zero-install*, *cross-platform* executable that can run on Linux, Android, HaikuOS, Windows, Mac, etc.

See [http://rebolsource.net](http://rebolsource.net)

If you are the sort of person who just clicks "yes" to installing packages or DLLs without concern about size or dependencies, the biggest advantages of Draem will probably be off your radar.  But if you think these matters are worth considering, perhaps it's worth looking at to see how it works.  Rebol 3 was open sourced in December of 2012, and a compiled variant called [Red](http://red-lang.org) is under heavy development.

This software is released under the [BSD License](http://en.wikipedia.org/wiki/BSD_licenses).


## HISTORY

Draem was initially designed as a simple system for making a website which facilitated the easy authoring of a stylized "screenplay" format of blogging.  This was primarily for journaling [lucid dreams](http://en.wikipedia.org/wiki/Lucid_dream), biased toward a traditional "movie script" style.  This was to help build [realityhandbook.org](http://realityhandbook.org), by rescuing unstructured information from captivity at [realityhandbook.livejournal.com](http://realityhandbook.livejournal.com).

The scope of the project then expanded to try and be a more general purpose markup system, for another data rescue operation *(this time, out of a somewhat archaic WordPress installation)*.


## FORMAT

The input format is a series of blocks, representing sequential sections of the dream dialogue.  The rule is that the behavior of any block that would accept a single item as legal is the same as omitting the block.  So if you can write:

    [Foo]

Then you could have just written:

    Foo

However, you cannot omit the block if something takes options.  So instead of writing:

    [Foo FooOption]

You *cannot* just write:

    Foo FooOption

Whitespace between items is ignored, per Rebol's rules.  So a series of items are presumed to be different sections.  So this would produce three separate "paragraphs", despite the lack of a newline:

    {One} {Two} {Three}

Blocks can be used to group items in places where a single item would be expected.  So for instance, this is ia legitimate way of passing two "groups" to Foo: 

    [Foo [{Baz} {Bar}] [{Mumble} {Frotz}]]

This is applicable to cases like bulleted lists, where you might want to put multiple sections under a single bullet.  But most constructs do not require the blocks.



### Exposition

Simple exposition or narration is just a string inside of a block.

    {See, I'm naked in church when I meet a dinosaur.  I try to run but
      my feet have been nailed to the floor.  Then a midget pushes me through
      a revolving door.  And I'm back in the very same place I was before...}

( apologies to [Weird Al Yankovic](http://www.youtube.com/watch?v=K4fezNM7-Kk ) )

Putting it in a block is optional, but not necessary.  The string itself is processed as a subset of Markdown, similar to what can appear in StackOverflow comments or chat:

    {You can do *italics*, **bold**, [web links](http://example.com),
        code in `backticks`, and maybe more someday...}


### Dialogue

A line of dialogue starts with a hyphenated character name followed by a colon.  Although any "SET-WORD!" (in Rebol terminology) would be legal here, keeping the names as simple as possible and not including punctuation or numbers is best.  Dashes in the set-words are rendered as spaces in the generated HTML:

    [taco-bell-dog: {Yo quiero taco bell.}]

It's possible to add an action to a line of dialogue by enclosing it in angle brackets as the second item in a dialogue block:

    [purple-cheetah: <growling fiercely> {Give me back that shoe pie!}]

The contents of the action must be a valid Rebol TAG!, which is a subclass of string that permits most characters.


### Notes

Sidenotes are indicated with a block beginning with the word! NOTE:

    [note {I told the dream alien it was the year 2000, but it's
     actually 2013 at the time of this writing.}]

Multi-line notes are also possible, just put the items in a sequence.  They will be considered to be different achieved by instead of having a string as the second argument, putting a block there instead.  In that block, all line formats are legal.  The template generator will wrap that up in a blockquote.

    [note
        {One}
        [person-two: <surprised> {I can put dialogue in notes?}]
        [
            {^-- Pointless grouping block in this case.}
            {but it's legal...}
        ]
    ]


### Updates

An update notice is very much like a note, only it has an optional date as the first item.  It would typically be rendered more strongly.

    [update 12-Dec-2012 {Rebol is now open source!}]

Whether a sidenote should also allow dates is up in the air.  It's possible.  The other question, as Draem's standards for optional dialect parameters evolve, is whether the dialect format should be this freeform.


### Headings

Currently there's only a single level:

    [heading "This is a section heading"]

If you want to make it possible to hyperlink directly to that heading with an anchor, use a file! at the end:

    [heading "This has an anchor" %anchor-name]

In the future, an optional number could indicate the level of heading, e.g. `[heading 3 "third level"]`.


### Pictures

The picture facility is a little bit half-baked at the moment, but what it does is lets you specify a URL and a caption.  So for instance:

    [picture http://example.com/image.jpg {Example image}]
    

### URLs

A simple URL will just be turned into a clickable hyperlink whose text will the text of the link:

    https://github.com/hostilefork/draem

If you put a string after it, then that will be the string on the link:

    [https://github.com/hostilefork/draem {Draem Static Website Generator}]


### YouTube Videos

Takes a URL and then an optional size to embed:

    [youtube https://www.youtube.com/watch?v=ADBKdSCbmiM 640x400]

I am considering auto-detecting URLs, somewhat in the spirit of how StackOverflow does what they call "oneboxing".


### Lists

Similar to how NOTE works.  You can put any structural unit into a list slot.

    [list
        {One.}
        [person-two: <impressed> {Looks pretty fancy!}]
        [
            {^-- This block grouping has a point!}
            {Despite two elements here, only one bullet...}
        ]
    ]


### Quotes

Something meant to be targeting something like an HTML blockquote.  You do not need to put quotation marks in the content:

If you want to attribute it, use the special option /source:

    [quote
        {Security is mostly a superstition. It does not
        exist in nature, nor do the children of men as
        a whole experience it. Avoiding danger is no
        safer in the long run than outright exposure.}

        {Life is either a daring adventure, or nothing.}

        /source [http://en.wikipedia.org/wiki/Helen_Keller {Helen Keller}]
    ]

I can't think of a good reason to let you put lines of dialogue or bulleted lists there.  But at the moment it supports everything.  I'd suggest just making it a simple string or a link format, though.

This way of specifying parameters to constructs which are intended to accept flat lists is something that will need to be revisited.


### Dividers

A divider creates a visual horizontal line:

    divider


### Separators

A separator just leaves a line of extra space in a context, without drawing a line:

    separator


### More

WordPress had a special invisible indicator for a cut point between the lead-in of your content that would be on the main blog roll, and the "rest".  Because one of the data sets I imported had these indicators, I included them.  I'm not sure how they'll be handled ultimately.  For the moment they are just ignored.

    more


### HTML

You would ideally use the nicer Markdown syntax which is handled in raw strings.  But sometimes raw HTML is needed (tables, etc.)

    [html {<p>Wouldn't this look <i>nicer</i> as Markdown?</p>}]

Note that the HTML really is raw; it will have the block-level-element bracketing that you would get with an ordinary string.


## SYNCHRONIZATION NOTES

Once a static site is built, there could be a lot of overhead in transferring all the generated templates each time.  This can be sped up with the [Rsync](http://en.wikipedia.org/wiki/Rsync) tool.

The configuration for Rsync is in the `/etc/rsyncd.conf`, and might look something like this:

    motd file = /etc/rsyncd.motd
    log file = /var/log/rsyncd.log
    pid file = /var/run/rsyncd.pid
    lock file = /var/run/rsync.lock
    read only = yes
    list = no

    [draem-templates]
    path = *** # path to where the templates are goes here
    comment = Draem Template Sync
    uid = *** # user id goes here
    gid = nogroup
    read only = no
    list = yes
    auth users = *** # user id here
    secrets file = /etc/rsyncd.scrt

If that is configured properly, then draem-templates names a directory that can be sync'd.

To get a sync to run, then start the daemon on the server side with:

    sudo rsync --daemon --no-detach -vvv

On the client side, run:

    rsync --progress --recursive templates/* [your login @ your domain]::draem-templates

If that doesn't work, then the `::` syntax for using the configuration may be incorrect.  When I have had problems with that, this alternative call from the client has worked for me:

    rsync --progress --recursive templates/* [your login @ your domain]:[remote path]