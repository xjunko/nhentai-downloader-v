import os
import x.json2
import net.http


struct Doujin {
	cdn_url string = 'https://i.nhentai.net/galleries'
	mut:
		id string
		media_id string
		title map[string]json2.Any
		pages json2.Any
}

pub fn (mut d Doujin) from_json(f json2.Any) {
	obj := f.as_map()
	for key, value in obj {
		match key {
			'id' { d.id = value.str() }
			'media_id' { d.media_id = value.str() }
			'title' { d.title = value.as_map() }
			'images' { d.pages = value.as_map()['pages'] }	
			else {}
		}
	}
}


fn (mut d Doujin) download_doujin() {
	mut threads := []thread ?{}

	// Check if doujin folder exists
	if !os.exists('downloads/${d.id}/') {
		os.mkdir('downloads/${d.id}/') or {
			println('Failed to create doujin folder: $err')
		}
	}

	for i, page_ in d.pages.arr() {
		page := page_.as_map()
		format := match page['t'].str() {
			'j' { 'jpg' }
			'p' { 'png' }
			'g' { 'gif'}
			else {'jpg'}
		}

		threads << go http.download_file(
			'$d.cdn_url/$d.media_id/${i+1}.$format',
			'downloads/$d.id/${i+1}.$format'
			)
	}

	for i, task in threads {
		println('Starting page #${i+1}')
		task.wait() or {
			println('Page #${i+1} failed: $err')
		}
		println('Finished page #${i+1}')
	}

}

[heap]
struct NHentai {
	api_url string = 'https://nhentai.net/api/gallery'
}

fn (mut d NHentai) from_code(code string) ?Doujin {
	println('> Doujin code: ${code}')

	resp_raw := http.get('${d.api_url}/${code}') or {
		println('Request failed: $err')
		return err
	}

	if resp_raw.status_code != 200 {
		return error('Status code is not 200')
	}

	resp := json2.decode<Doujin>(resp_raw.text) or {
		println('Failed to decode json!: $err')
		return err
	}

	println('Doujin id: $resp.id')
	println('Doujin name: ${resp.title["pretty"]} | ${resp.pages.as_map().len} pages')

	return resp
}


fn main() {
	args := os.args.clone()

	if args.len < 2 {
		println('nHentai shit downloader')
		println('error: wheres the code retard \n')
		println('args:')
		println('* code: int - the fucking code for nhentai')
		return
	}	

	// Check download folder
	if !os.exists('downloads') {
		os.mkdir('downloads') or {
			println('Failed to create download folder!: $err') 
			// should never happen unless
			// some bullshit perms is fucking up the program
		}
	}

	code := args[1]
	mut doujin := NHentai{}.from_code(code) or {
		println('Failed to get Doujin: $err')
		return
	}

	// Download; very broken atm lol
	doujin.download_doujin()
	
}
