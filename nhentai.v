import os
import json
import time
import rand
import net.http


struct Doujin {
	mut:
		id int
		media_id string
		title map[string]string  // this took awhile to figure out lmao i forgot how V works
		pages int [json: num_pages]
}


fn (mut d Doujin) download_doujin() {
	cdn_url := 'https://i.nhentai.net/galleries'
	mut threads := []thread ?{}

	// Check if doujin folder exists
	if !os.exists('downloads/${d.id.str()}/') {
		os.mkdir('downloads/${d.id.str()}/') or {
			println('Failed to create doujin folder: $err')
		}
	}

	for page in 1 .. d.pages + 1 {
		threads << go http.download_file('$cdn_url/$d.media_id/${page.str()}.jpg', 'downloads/${d.id.str()}/${page.str()}.jpg')
	}

	
	for i, t in threads {
		time.sleep(
			rand.f64_in_range(1, 5) * time.second
			)
		println('#$i: Starting!')
		t.wait() or {
			println('#Thread $i Failed: $err')
		}
		println('#$i: Completed!')
	}
}

[heap]
struct NHentai {
	api_url string = 'https://nhentai.net/api/gallery'
}

fn (mut d NHentai) from_code(code string) Doujin {
	println('> Doujin code: ${code}')

	resp_raw := http.get(
		'${d.api_url}/${code}'
		) or {panic('Request failed: $err')}

	resp := json.decode(Doujin, resp_raw.text) or {panic('Failed to decode json!: $err')}

	println('Doujin id: $resp.id')
	println('Doujin name: $resp.title["pretty"] | $resp.pages pages')

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
	if !os.exists('download') {
		os.mkdir('downloads') or {
			println('Failed to create download folder!: $err') // should never happen unless
															   // some bullshit perms is fucking up the program
		}
	}

	code := args[1]
	mut doujin := NHentai{}.from_code(code)

	// Download; very broken atm lol
	doujin.download_doujin()
	
}
