import net.http
import net.html
import os

struct Doujin {
	base_url string = 'https://nhentai.net/g'
	cdn_url string = 'https://i.nhentai.net/galleries'

	mut:
		code string
		title string
		pages_url []string

		// internal
		cdn_code string
		pages int
		raw_html http.Response
		parser html.DocumentObjectModel
}

fn (mut d Doujin) from_code(code string) &Doujin {
	//mut code := code_.str()[..code_.str().len-1] // for some reason int have a dot at the end
	println('Doujin Code: ${code}')

	d.code = code
	d.raw_html = http.get('${d.base_url}/${d.code}/') or {panic('Request failed!')}
	d.parser = html.parse(d.raw_html.text)

	// find the cdn code
	meta := d.parser.get_tag_by_attribute_value('property', 'og:image')[0]
	if 'content' !in meta.attributes {
		panic('Failed to find meta!')
	}
	d.cdn_code = (meta.attributes['content']).split('/')[4] // would be cool if i can just [-2] instead of [4]

	// get pages count
	d.pages = d.parser.get_tag_by_attribute_value('class', 'thumb-container').len

	for page in 1 .. d.pages + 1 {
		//d.pages_url << d.cdn_url + d.cdn_code + '/' + page.str() + '.jpg' // not cool looking, does v have string format?
		d.pages_url << '${d.cdn_url}/${d.cdn_code}/${page.str()}.jpg' // it does.
	}

	// metadata stuff
	d.title = d.parser.get_tag_by_attribute_value('class', 'title')[0].text()

	print('Doujin name: ${d.title}')
	println('Done parsing')

	return d
}

fn (d Doujin) download_pages() {
	println('Downloading...')
	println('Pages: ${d.pages_url.len}')

	if d.pages_url.len == 0 {
		println('uh idk man theres no pages to download so... bye?')
		return
	}

	// make a folder for this doujin if havent
	if !os.exists('downloads/${d.code}') {
		os.mkdir('downloads/${d.code}') or {}
	}

	
	for n, page in d.pages_url {
		println('Downloading page: ${n+1} | Url: ${page}')
		http.download_file(page, 'downloads/${d.code}/${n+1}.jpg') or {println('Failed to download page ${n+1}')}
		println('Downloaded page: ${n+1}/${d.pages_url.len}')
	}
}

fn main(){
	args := os.args.clone()

	if args.len < 2 {
		print('wheres the code retard')
		print('\n')
		print('\n')
		print('args: \n')
		print('* code: int - the fucking code for nhentai')
		print('\n')
		return
	}

	code := args[1]
	doujin := Doujin{}.from_code(code)

	// check download folder
	if !os.exists('downloads') {
		os.mkdir('downloads') or {} // i mean it shouldnt fail
	}
	
	// Download 
	doujin.download_pages()


}


/*
a := Doujin{}.from_code(177013)
// try download?
for n, page in a.pages_url {
	http.download_file(page, '${n}.jpg') or {println('Failed to download page ${n}')}
	println('Downloaded ${n}')	
}
*/


