Rebol [
    Title: "Make Timeline"
    Description: --{
        This is a small experiment which builds the XML file needed so that
        the entries can be shown on a SIMILE timeline:

        http://www.simile-widgets.org/timeline/

       More modern timeline codebases now exist for JavaScript and HTML5,
       and it would probably be a good idea to update to another solution,
       as the SIMILE widgets seem to have not had any updates for some time.
    }--

    Home: http://draem.hostilefork.com
    License: 'mit

    Date: 20-Oct-2010
    Version: 3.0.4

    ; Header conventions: http://www.rebol.org/one-click-submission-help.r
    File: %make-timeline.reb
    Type: 'dialect
    Level: 'intermediate
]

do %common.reb

; "Nov 29 1963 00:00:00 GMT-0600"
; Rebol is close "13-Oct-2009/19:51:30-7:00"
to-timeline-date: function [d [date!]] [

    ; Not all Rebol dates have times or time zone info.  Force it for
    ; convenience in the parse.
    ;
    if not d.time [
        d.time: 10:20:03
        d.zone: -04:00
    ]

    date-string: to text! d
    rule: [
        day-string: across to "-" one
        month-string: across to "-" one
        year-string: across to "/" one
        ;-- current potential bug that timezone is being omitted...
        time-string: across to ["+" | "-" | <end>]
        gmt-string: across to <end>
    ]
    if not parse:match date-string rule [
        fail ["Could not convert" date-string "to timeline format."]
    ]

    if empty? gmt-string [
        gmt-string: "-05:00"
    ]

    combine [
        month-string space day-string space year-string space
        time-string space "GMT" gmt-string
    ]
]

make-timeline: function [entries [block!] xml-filename [file!]] [
    draem/stage "TIMELINE OUTPUT"

    timelinexml: combine [
        -{<data}-
        space -{wiki-url="}- draem.config.site-url -{"}-
        space -{wiki-section="}- draem.config.site-name -{ Timeline"}-
        -{>}-
    ]

    for-each entry entries [
        append timelinexml combine [
            tab tab -{<event start="}- to-timeline-date entry.header.date -{"}-
            tab tab tab -{title="}- stringify entry.header.slug -{"}-
            tab tab tab -{>}-
            entry.header.title
            tab tab tab </event>
        ]
    ]

    append timelinexml [
        </data>
    ]

    write:lines xml-filename timelinexml
]
