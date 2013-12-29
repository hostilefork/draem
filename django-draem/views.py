from django.template import RequestContext, loader
from draems.models import Poll
from django.http import HttpResponse

from pyamf.remoting.gateway.django import DjangoGateway

def about(request):
    latest_poll_list = Poll.objects.all().order_by('-pub_date')[:5]
    t = loader.get_template('about.html')
    c = RequestContext(request, {
        'latest_poll_list': latest_poll_list,
    })
    return HttpResponse(t.render(c))

def contact(request):
    latest_poll_list = Poll.objects.all().order_by('-pub_date')[:5]
    t = loader.get_template('contact.html')
    c = RequestContext(request, {
        'latest_poll_list': latest_poll_list,
    })
    return HttpResponse(t.render(c))

def index(request):
    t = loader.get_template('index.html')
    c = RequestContext(request, {
    })
    return HttpResponse(t.render(c))

def entry(request, category, slug):
	latest_poll_list = Poll.objects.all().order_by('-pub_date')[:5]
	t = loader.get_template(category + '/' + slug + '.html')
	c = RequestContext(request, {
        	'latest_poll_list': latest_poll_list,
	})
	return HttpResponse(t.render(c));

def lucid_dream(request, slug):
	return entry(request, "lucid-dream", slug);

def post(request, slug):
	return entry(request, "post", slug);
def page(request, slug):
	return entry(request, "page", slug);

def guest_dream(request, slug):
	return entry(request, "guest-dream", slug);
def non_lucid_dream(request, slug):
	return entry(request, "non-lucid-dream", slug);

def open_letter(request, slug):
	return entry(request, "open-letter", slug);

def misc(request, slug):
	return entry(request, "misc", slug);

def essay(request, slug):
	return entry(request, "essay", slug);

def hypnosis(request, slug):
	return entry(request, "hypnosis", slug);

def character(request, slug):
	t = loader.get_template('characters/' + slug + '.html')
	c = RequestContext(request, {
	})
	return HttpResponse(t.render(c));

def character_list(request):
	t = loader.get_template('characters.html')
	c = RequestContext(request, {
	})
	return HttpResponse(t.render(c));

def tag(request, slug):
	t = loader.get_template('tags/' + slug + '.html')
	c = RequestContext(request, {
	})
	return HttpResponse(t.render(c));

def tag_list(request): 
	t = loader.get_template('tags.html')
	c = RequestContext(request, {
	})
	return HttpResponse(t.render(c));

def category(request, slug):
	t = loader.get_template('categories/' + slug + '.html')
	c = RequestContext(request, {
	})
	return HttpResponse(t.render(c));

def category_list(request):
	t = loader.get_template('categories.html')
	c = RequestContext(request, {
	})
	return HttpResponse(t.render(c));

def timeline(request):
	t = loader.get_template('timeline.html')
	c = RequestContext(request, {
	})
	return HttpResponse(t.render(c));

def timeline_history_hack(request):
	# http://simile.mit.edu/wiki/Exhibit/Template/_history_.html
	return HttpResponse('<html><body></body></html>');

def eatme(request):
    latest_poll_list = Poll.objects.all().order_by('-pub_date')[:5]
    t = loader.get_template('eatme.xml')
    c = RequestContext(request, {
        'latest_poll_list': latest_poll_list,
    })
    return HttpResponse(t.render(c))

def feed(request):
    	latest_poll_list = Poll.objects.all().order_by('-pub_date')[:5]
	t = loader.get_template('atom.xml')
    	c = RequestContext(request, {
        	'latest_poll_list': latest_poll_list,
	})
	return HttpResponse(t.render(c), mimetype="application/atom+xml")
