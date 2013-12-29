Rebol [
	Title: "Make Atom Feed"
	Description: {

	Build an RSS ATOM xml file from the last N entries.

	}

	Home: http://realityhandbook.org/
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
	 {converts a date! to a string which complies with the ISO 8602 standard.
	  If the time is not set on the input date, a default of 00:00 is used.}
	 
	the-date [date!]
		"The date to be reformatted"
	/timestamp
		{Include the timestamp}
][ 

	iso-date: copy ""           

	; old code probably supplanted by /timestamp refinement
	; from http://www.rebol.org/view-script.r?script=iso-8601-date.r
	comment [
		unless timestamp [
			return to string! join date/year
			["-" copy/part tail join "0" [date/month] -2 "-" copy/part tail join "0" [date/day] -2 ]
		]
	]

	if timestamp [
		either the-date/time [
			; the date has a time
			insert iso-date rejoin [
				"T"

				; insert leading zero if needed	            
				either the-date/time/hour > 9
					[the-date/time/hour]
					[join "0" [the-date/time/hour]]
				":"
				either the-date/time/minute > 9
					[the-date/time/minute]
					[join "0" [the-date/time/minute]]
				":"

				; Rebol only returns seconds if non-zero
				either the-date/time/second > 9 
					[to-integer the-date/time/second]
					[join "0" [to-integer the-date/time/second]]
				
				either the-date/zone = 0:00 [
					; UTC
					"Z"                           
				][
					rejoin [
						; + or - UTC
						either the-date/zone/hour > 0
							["+"]
							["-"]
						either  (absolute the-date/zone/hour) < 10
							[join "0" [absolute the-date/zone/hour]]
							[absolute the-date/zone/hour]
						{:}
						either the-date/zone/minute < 10
							[join "0" [the-date/zone/minute]]
							[the-date/zone/minute]
					]
				]
			] ; end insert  
		][
			; the date has no time
			iso-date: " 00:00:00Z" 
		]
	]
	 
	insert iso-date rejoin [
		join copy/part "000" (4 - length? to-string the-date/year)
			[the-date/year]
		"-"
		either the-date/month > 9
			[the-date/month]
			[join "0" [the-date/month]]
		"-"
		either the-date/day > 9
			[the-date/day]
			[join "0" [the-date/day]]
	 ] ; end insert
   
	return head iso-date   
]


atomid-from-url: function [
	{Generates an "atom ID" from a URL.  I'm not sure if this is correct,
	but I got my information from:

		http://diveintomark.org/archives/2004/05/28/howto-atom-id

	...which was the #1 Google hit for "atom ID".}

	url [url! string!]
		{The URL to be specified}

	d [date!]
		{Date associated with URL, included in atom ID}
] [
	if string? url [
		print "TEMPORARILY DISABLED!!!"
		return "atomid-disabled"
	]

	str: to string! url
	replace str "http://" {}
	replace/all str "#" "/"
	replace str "/" rejoin ["," to-iso8601-date d ":"]
	insert str "tag:"
	return str
]


make-atom-feed: function [
	{Generates an RSS "Atom" feed, so that polling requests from RSS
	readers will know when there are new entries available.}

	entries [block!]

	xml-filename [file!]
		{Name of the output file (should end in .xml)}

	atom-length [integer!]
		{Number of most recent entries to feed}
] [
	atom-xml: rejoin compose [{<?xml version="1.0" encoding="utf-8"?>
		
	<feed xmlns="http://www.w3.org/2005/Atom">
	 
		<title>Brian's Hostilefork Blog Feed</title>
		<subtitle>Extraordinary Lucid Dream Reports</subtitle>
		<link href="http://blog.hostilefork.com/brian/feed/" rel="self" />
		<link href="http://blog.hostilefork.com/brian/" />
		<id>tag:hostilefork.com,1975-04-21:</id>
		<updated>} (to-iso8601-date/timestamp now) {</updated>
		<author>
			<name>Realityhandbook</name>
		</author>
	}]

	foreach entry entries [
		if 0 = atom-length [
			break
		]
		-- atom-length
		append atom-xml rejoin compose [{
		<entry>
			<title>} (entry/header/title) {</title>}
	;		<link href="} (url-for-entry entry) {" />
	{
			<link rel="alternate" type="text/html" href="} (url-for-entry entry) {" />}
	;		<link rel="edit" href="} ("http://example.org/2003/12/13/atom03/edit") {"/>
	{
			<id>} (atomid-from-url url-for-entry entry entry/header/date) {</id>
			<updated>} (to-iso8601-date/timestamp entry/header/date) {</updated>
			<summary>} (stringify entry/header/category)
				{ - Tags: } (comma-separated entry/header/tags)
			{</summary>
		</entry>
	}
		]
	 ]
	 
	append atom-xml {</feed>}

	write xml-filename atom-xml
]