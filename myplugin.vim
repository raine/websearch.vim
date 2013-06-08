function! s:open_url(query, url)
  let url = substitute(a:url, '{query}', s:encode_url(a:query), '')
  let command = 'open ' . shellescape(url)
  call system(command)
endfunction

function! s:encode_url(str)
  if has('perl')
    perl << EOF
      use URI::Escape;

      $str = VIM::Eval('a:str');
      $str =~ s/^\s+|\s+$//g ; 
      $escaped = uri_escape($str);

      VIM::DoCommand "let str='$escaped'";
EOF
    return str
  endif
endfunction

function! s:prompt(name)
  return input(a:name . ': ')
endfunction

function! s:run_mapping(i, ...)
  let [ key, name, url ] = g:plugin_url_mappings[a:i]

  if len(a:000) > 0 
    let query = a:000[0]
  else
    let query = s:prompt(name)
  endif

  if len(query) > 0
    call s:open_url(query, url)
  endif
endfunction

function! s:visual_mode(type, i)
  let sel_save   = &selection
  let reg_save   = @@
  let &selection = "inclusive"

  if a:type ==# 'v'
    silent exe "normal! `<" . a:type . "`>y"
  elseif a:type ==# 'V'
    silent exe "normal! '<V'>y"
  endif

  let query = substitute(@@, "^\\s\\+\\|\\s\\+$", '', 'g')
  let query = substitute(query, "\n", '', 'g')

  call s:run_mapping(a:i, query)

  let &selection = sel_save
  let @@ = reg_save
endfunction

function! s:create_mappings()
  for i in range(0, len(g:plugin_url_mappings)-1)
    let key = g:plugin_url_mappings[i][0]
    execute 'nnoremap <silent>' key ':call <SID>run_mapping(' . i . ')<CR>'
    execute 'vnoremap <silent>' key ':<C-U>call <SID>visual_mode(visualmode(), ' . i . ')<CR>'
  endfor
endfunction

call s:create_mappings()
