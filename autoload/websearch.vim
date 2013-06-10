function! s:open_url(query, url)
  let url = substitute(a:url, '{query}', s:encode_url(a:query), '')
  let command = s:open_url_command . ' ' . shellescape(url)
  call system(command)
endfunction

function! s:get_command()
  if has('mac')
    let cmd = 'open'
  elseif executable('xdg-open')
    let cmd = 'xdg-open'
  endif

  let s:open_url_command = cmd
endfunction

function! s:encode_url(str)
  if has('perl')
    perl << EOF
      use URI::Escape;

      $str = VIM::Eval('a:str');
      $str =~ s/^\s+|\s+$//g;
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
  let [ key, name, url ] = g:websearch_mappings[a:i]

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

function! websearch#create_mappings()
  if exists('g:websearch_mappings')
    for i in range(0, len(g:websearch_mappings)-1)
      let key = g:websearch_mappings[i][0]
      execute 'nnoremap <silent>' key ':call <SID>run_mapping(' . i . ')<CR>'
      execute 'vnoremap <silent>' key ':<C-U>call <SID>visual_mode(visualmode(), ' . i . ')<CR>'
    endfor
  endif

  call s:get_command()
endfunction

function! websearch#WebSearchDefault(arg)
  if !exists('g:websearch_mappings')
    echohl ErrorMsg | echomsg 'WebSearch: g:websearch_mappings not set' | echohl None
    return
  endif

  if exists('b:websearch_default_mapping')
    let default = b:websearch_default_mapping
  elseif exists('g:websearch_default_mapping')
    let default = g:websearch_default_mapping
  else
    let default = 0
  end

  if a:arg ==# 'v'
    call s:visual_mode(visualmode(), default)
  else
    if len(a:arg) > 0
      let query = expand(a:arg)
    else
      let query = expand('<cword>')
    endif

    call s:run_mapping(default, query)
  endif
endfunction


function! websearch#WebSearchList()
  if exists('g:websearch_mappings')
    let max_len = s:max_lens_list_of_lists(g:websearch_mappings)
    for [ key, name, url ] in g:websearch_mappings
      echo printf('%-' . max_len[0] . 's %-' . max_len[1] . 's %s', key, name, url)
    endfor
  endif
endfunction

function! s:max_lens_list_of_lists(list)
  let max_len = []
  for e in a:list[0]
    call insert(max_len, 0)
  endfor

  for item in a:list
    for i in range(0, len(item)-1)
      let len = len(item[i])
      if max_len[i] < len
        let max_len[i] = len
      endif
    endfor
  endfor

  return max_len
endfunction
