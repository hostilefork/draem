Rebol [
	Title: "Make Timeline"
	Description: {

	This is a small experiment which builds the XML file needed so that 
	the dreams can be shown on a SIMILE timeline:

		http://www.simile-widgets.org/timeline/

	More modern timeline codebases now exist for JavaScript and HTML5,
	and it would probably be a good idea to update to another solution,
	as the SIMILE widgets seem to have not had any updates for some time.

	}

	Home: http://realityhandbook.org/
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
	date-string: to string! d
	rule: [
		copy day-string to "-" skip 
		copy month-string to "-" skip 
		copy year-string to "/" skip
		copy time-string to ["+" | "-"]
		copy gmt-string to end
	]
	either parse date-string rule [
		rejoin [month-string space day-string space year-string space time-string space "GMT" gmt-string]
	] [
		throw make error! form ["Could not convert" date-string "to timeline format."]
	]
]

make-timeline: function [entries [block!] xml-filename [file!]] [ 
	timelinexml: reduce [
		{<data>}
		rejoin [tab {wiki-url="} draem-config/site-url {"}]
		rejoin [tab {wiki-section="} draem-config/site-name { Timeline"}]
		{>}
	]

	foreach entry entries [
		print entry/header/slug
		append timelinexml reduce [
			rejoin [tab tab{<event start="} to-timeline-date entry/header/date {"}]
			rejoin [tab tab tab {title="} stringify entry/header/slug {"}]
			rejoin [tab tab tab {>}]
			entry/header/title
			rejoin [tab tab tab {</event>}] 
		]
	]

	append timelinexml [
		{</data>}
	]

	write/lines xml-filename timelinexml
]