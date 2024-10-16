Rebol [
    Title: "Make Atom Feed"
    Description: --{
        Build an RSS ATOM xml file from the last N entries.
    }--

    Home: http://draem.hostilefork.com
    License: 'mit

    Date: 20-Oct-2010
    Version: 3.0.4

    ; Header conventions: http://www.rebol.org/one-click-submission-help.r
    File: %make-atom-feed.reb
    Type: 'dialect
    Level: 'intermediate
]

do %common.reb

; From http://www.rebol.org/view-script.r?script=to-iso-8601-date.r
; had to tweak to meet the specifications of date construct, http://tools.ietf.org/html/rfc4287

to-iso8601-date: function [
    "Converts a date! to a string which complies with the ISO 8602 standard"

    the-date [date!]
    /timestamp "Include the timestamp, defaults to 00:00 if not present"
][
    iso-date: copy ""

    ; old code probably supplanted by /timestamp refinement
    ; from http://www.rebol.org/view-script.r?script=iso-8601-date.r
    comment [
        if not timestamp [
            return to text! join date.year
            ["-" copy:part tail join "0" [date.month] -2 "-" copy:part tail join "0" [date.day] -2 ]
        ]
    ]

    if timestamp [
        either the-date.time [
            ; the date has a time
            insert iso-date combine [
                "T"

                ; insert leading zero if needed
                if not (the-date.time.hour > 9) ["0"]

                the-date.time.hour

                ":"

                ; again, leading zero if needed...
                if not (the-date.time.minute > 9) ["0"]

                the-date.time.minute

                ":"

                ; once again zero, note Rebol only returns seconds if non-zero
                if not (the-date.time.second > 9) ["0"]

                (to integer! the-date.time.second)

                ; !!! Rebol2 and R3-Alpha gave back 0:00 as the time zone
                ; of dates with no zone component.  Ren-C considers the zone
                ; to be missing, and will generate an error with regular path
                ; picking, or a void if using GET-PATH!.  This ANY glosses
                ; the difference.
                ;
                either (any [:the-date.zone 0:00] = 0:00) [
                    ; UTC
                    "Z"
                ][
                    [
                        ; + or - UTC
                        either (the-date.zone.hour > 0) ["+"] ["-"]

                        if ((absolute the-date.zone.hour) < 10) ["0"]

                        absolute the-date.zone.hour

                        ":"

                        if (the-date.zone.minute < 10) ["0"]

                        the-date.zone.minute
                    ]
                ]
            ]
        ] [
            ; the date has no time
            iso-date: " 00:00:00Z"
        ]
    ]

    insert iso-date combine [
        copy:part "000" (4 - length? to text! the-date.year)

        the-date.year

        "-"

        if (the-date.month > 9) ["0"]

        the-date.month

        "-"

        if (the-date.day > 9) ["0"]

        the-date.day
     ]

    return head iso-date
]


atomid-from-url: function [
    "Atom ID: http://diveintomark.org/archives/2004/05/28/howto-atom-id"

    url [url! text!]
    d [date!]
][
    str: to text! url
    replace:one str "http://" void
    replace str "#" "/"
    replace:one str "/" combine ["," to-iso8601-date d ":"]
    insert str "tag:"
    return str
]


make-atom-feed: function [
    "Generates an RSS Atom feed (pollable for when new entries added)"

    entries [block!]

    xml-filename "Output file (should end in .xml)"
        [file!]
    atom-length "Number of most recent entries to feed"
        [integer!]
][
    draem/stage "ATOM FEED OUTPUT"

    atom-xml: combine [
        <?xml version="1.0" encoding="utf-8"?>

        <feed xmlns="http://www.w3.org/2005/Atom">

        <title> draem.config.site-title </title>
        <subtitle> draem.config.site-tagline </subtitle>
        -{<link href="}- draem.config.site-url -{feed/" rel="self" />}-
        -{<link href="}- draem.config.site-url -{" />}-
        <id> -{tag:}- draem.config.rss-tag -{,1975-04-21:}- </id>
        <updated> to-iso8601-date:timestamp now </updated>
        <author>
            <name> draem.config.site-author </name>
        </author>
    ]

    for-each entry entries [
        if not any [ ;-- don't allow pages to appear in the rss atom for now
            draem/next-entry entry.header
            draem/previous-entry entry.header
        ][
            continue
        ]

        sorted-tags: map-each tag draem/entry-tags-by-popularity entry.header [
            stringify tag
        ]
        if 0 = atom-length [
            break
        ]
        atom-length: atom-length - 1
        append atom-xml combine:with [
            <entry>
                [<title> (entry.header.title) </title>]
            ;   <link href="} (url-for-entry entry) {" />
                [-{<link rel="alternate" type="text/html" href="}- url-for-entry entry -{" />}-]
            ;   <link rel="edit" href="} ("http://example.org/2003/12/13/atom03/edit") {"/>
                [<id> (atomid-from-url url-for-entry entry entry.header.date) </id>]
                [<updated> (to-iso8601-date/timestamp entry.header.date) </updated>]
                <summary>
                [-{Tags: }- combine:with sorted-tags [-{,}- space]]
                </summary>
            </entry>
        ] newline
     ]

    append atom-xml </feed>

    write xml-filename atom-xml
]
