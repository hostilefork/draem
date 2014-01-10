# Draem

Draem is a static website builder, which is along the lines of something like [Jekyll](http://jekyllrb.com/)...but using open source [Rebol 3](http://en.wikipedia.org/wiki/Rebol).  Blog entries (or pages) are written in a "dialect" of the language, so despite their customized appearance they have no parser of their own.  Rather, they embrace the carefully-chosen limits of the host system to create a [Domain-Specific Language](http://en.wikipedia.org/wiki/Domain-specific_language).

The tool is mostly notable for the reasons Rebol is notable.  This includes depending only on a *half-megabyte*, *zero-install*, *cross-platform* executable that can run on Linux, Android, HaikuOS, Windows, Mac, etc.

See [http://rebolsource.net](http://rebolsource.net)

If you are the sort of person who just clicks "yes" to installing packages or DLLs without concern about size or dependencies, the biggest advantages of Draem will probably be off your radar.  But if you think these matters are worth considering, perhaps it's worth looking at to see how it works.  Rebol 3 was open sourced in December of 2012, and a compiled variant called [Red](http://red-lang.org) is under heavy development.


## History

Draem was initially designed as a simple system for making a website which facilitated the easy authoring of a stylized "screenplay" format of blogging.  This was primarily for journaling [lucid dreams](http://en.wikipedia.org/wiki/Lucid_dream), biased toward a traditional "movie script" style.  This was to help build [realityhandbook.org](http://realityhandbook.org), by rescuing unstructured information from captivity at [realityhandbook.livejournal.com](http://realityhandbook.livejournal.com).

*(Note: The author's belief is that documenting dreams...especially very atypical ones...may constitue a "data set" which would be useful to analyze.  For others interested in that particular concept, they may also be interested [Shadow Project](http://discovershadow.com/), which had a successful $82,577 KickStarter to develop mobile apps to assist in dream documention.)*

The scope of the project then expanded to try and be a more general purpose markup system, to rescue data out of a somewhat archaic WordPress installation.

---

The input format is a series of blocks, representing sequential sections of the dream dialogue.  Here are the block formats:

EXPOSITION

Simple exposition or narration is just a string inside of a block.

    [{See, I'm naked in church when I meet a dinosaur.  I try to run but
      my feet have been nailed to the floor.  Then a midget pushes me through
      a revolving door.  And I'm back in the very same place I was before...}]

( apologies to [Weird Al Yankovic](http://www.youtube.com/watch?v=K4fezNM7-Kk ) )

It is now likely that exposition will be changed to allow the block to be optional.


SIDENOTES

Sidenotes are indicated with a block beginning with the word! NOTE:

    [note {I told the dream alien it was the year 2000, but it's
     actually 2013 at the time of this writing.}]

Multi-line notes are achieved by instead of having a string as the second argument, putting a block there instead.  In that block, all line formats are legal.  The template generator will wrap that up in a blockquote.

    [note [[{One.}] [{Two.}] [{Three}]]]


DIALOGUE

A line of dialogue starts with a hyphenated character name followed by a colon.  Although any "SET-WORD!" (in Rebol terminology) would be legal here, keeping the names as simple as possible and not including punctuation or numbers is best.  Dashes in the set-words are rendered as spaces in the generated HTML:

    [taco-bell-dog: {Yo quiero taco bell.}]

It's possible to add an action to a line of dialogue by enclosing it in parentheses as the second item in a dialogue block:

    [purple-cheetah: ("growling fiercely") {Give me back that shoe pie!}]

The contents of the parentheses must be a string enclosed in quotes.


PICTURES

The picture facility is a little bit half-baked at the moment, but what it does is lets you specify a URL and a caption.  So for instance:

    [picture http://example.com/image.jpg {Example image}]
    

YOUTUBE VIDEOS

Takes a URL and then an optional size to embed:

    [youtube https://www.youtube.com/watch?v=ADBKdSCbmiM 640x400]

I am considering auto-detecting URLs, somewhat in the spirit of how StackOverflow does what they call "oneboxing".


LISTS

Similar to how NOTE works.  You can put any structural unit into a list slot.

    [list [{One.}] [{Two.}] [{Three.}]]
