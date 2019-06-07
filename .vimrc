" not compatible with the old-fashion vi mode
set nocompatible

" powerline
set rtp+=usr/local/lib/python2.7/dist-packages/powerline/bindings/vim
python3 from powerline.vim import setup as powerline_setup
python3 powerline_setup()
python3 del powerline_setup

" Setting up Vundle - the vim plugin bundler
let iCanHazVundle=1
let vundle_readme=expand('~/.vim/bundle/vundle/README.md')
if !filereadable(vundle_readme)
  echo "Installing Vundle.."
  echo ""
  silent !mkdir -p ~/.vim/bundle
  silent !git clone https://github.com/gmarik/vundle ~/.vim/bundle/vundle
  let iCanHazVundle=0
endif

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle
Bundle 'gmarik/vundle'

" My Bundles here:"
Plugin 'gmarik/Vundle.vim'
Plugin 'L9'
Plugin 'scrooloose/nerdtree'
Plugin 'Lokaltog/vim-powerline'
Plugin 'tpope/vim-fugitive'  "branch of powerline
Plugin 'c9s/colorselector.vim'
Plugin 'ap/vim-css-color'
Plugin 'gregsexton/MatchTag'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'python_match.vim'
Plugin 'tpope/vim-surround'
Plugin 'L4ys/molokai'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'vectorstorm/vim-csyn'
Plugin 'SirVer/ultisnips'
Plugin 'python-mode/python-mode'
Plugin 'editorconfig/editorconfig-vim'

"Plugin 'AutoComplPop'
Plugin 'othree/vim-autocomplpop'
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'tomtom/tlib_vim'
Plugin 'garbas/vim-snipmate'
Plugin 'honza/vim-snippets'
Plugin 'ironcamel/vim-script-runner'
Plugin 'xuhdev/SingleCompile'

"Plugin for tracecode 
Plugin 'hewes/unite-gtags'
Plugin 'Shougo/unite.vim'
Plugin 'majutsushi/tagbar'
Plugin 'Shougo/unite-outline'
Plugin 'Shougo/vimproc.vim'

"map vim record mode to none
map q <Nop>
scriptencoding utf-8
set encoding=utf-8    
set langmenu=en_US.UTF-8
language message en_US.UTF-8

" Vim settings and mappings
" You can edit them as you wish
" Configuration file for vim
set modelines=0     " CVE-2007-2438
set backspace=2     " more powerful backspacing
set autoindent      " enable autoindent

" allow plugins by file type (required for plugins!)
filetype plugin on
filetype indent on

" general
set linespace=0
set background=dark                                                                                      
set wildmenu
set smarttab
set showmatch       " Cursor shows matching ) and }
set showmode        " Show current mode  "
set cursorline      " cursorline highlighting
set expandtab
set ttyfast
set magic
set cmdheight=1
set tabstop=4
set lazyredraw
set softtabstop=4
set shiftwidth=4
set nu              " show line numbers
set ru              " ruler
set ai
set si
set wrap
set laststatus=2 
set ls=2            " always show status bar
set incsearch       " incremental search
set hlsearch        " highlighted search results
set autoread        " auto read when file is changed from outside "
set history=1000    " keep 50 lines of command line history  "
set scrolloff=3     " when scrolling, keep cursor 3 lines away from screen border
syntax on           " syntax highlight on

" tab length exceptions on some file types
autocmd FileType html setlocal shiftwidth=4 tabstop=4 softtabstop=4
autocmd FileType htmldjango setlocal shiftwidth=4 tabstop=4 softtabstop=4
autocmd FileType javascript setlocal shiftwidth=4 tabstop=4 softtabstop=4

" tab navigation mappings
map tn :tabn<CR>
map tp :tabp<CR>
map tm :tabm 
map tt :tabnew 
map ts :tab split<CR>
map <C-S-Right> :tabn<CR>
imap <C-S-Right> <ESC>:tabn<CR>
map <C-S-Left> :tabp<CR>
imap <C-S-Left> <ESC>:tabp<CR>

" navigate windows with meta+arrows
map <M-Right> <c-w>l
map <M-Left> <c-w>h
map <M-Up> <c-w>k
map <M-Down> <c-w>j
imap <M-Right> <ESC><c-w>l
imap <M-Left> <ESC><c-w>h
imap <M-Up> <ESC><c-w>k
imap <M-Down> <ESC><c-w>j

" old autocomplete keyboard shortcut
imap <C-J> <C-X><C-O>

" Comment this line to enable autocompletion preview window
" (displays documentation related to the selected completion option)
" Disabled by default because preview makes the window flicker
set completeopt-=preview

" Allow saving of files as sudo when I forgot to start vim using sudo.
cmap w!! w !sudo tee > /dev/null %

" simple recursive grep
nmap ,r :Ack 
nmap ,wr :Ack <cword><CR>

" use 256 colors when possible
if filereadable(expand('~/.vim/bundle/molokai/colors/molokai.vim'))
    let g:molokai_original = 1
    let t_Co = 256
    colorscheme molokai

    " colors for gvim
if has('gui_running')
    colorscheme molokai
endif

" autocompletion of files and commands behaves like shell
" (complete only the common part, list the options that match)
set wildmode=list:longest

" ============================================================================
" Plugins settings and mappings
" Edit them as you wish.
" ============================================================================

"Press F1 to open NERDTree
map <F1> :NERDTreeToggle<CR>
nmap ,t :NERDTreeFind<CR>
let NERDTreeIgnore = ['\.pyc$', '\.pyo$']
" autofocus on tagbar open
let g:tagbar_autofocus = 1

" <F5> toggles paste mode
set pastetoggle=<F2>

" ctrlp
set runtimepath^=~/.vim/bundle/ctrlp.vim
let g:ctrlp_custom_ignore = { 
    \ 'dir': '\.git$\|\.hg$:|\.svn$\|\.yardoc\|public\/images\|public\/system\|data\|log\|tmp$',
    \ 'file': '\.exe$\|\.so$\|\.dat$'
    \ }

function! CtrlPWithSearchText(search_text, ctrlp_command_end)
    execute ':CtrlP' . a:ctrlp_command_end
    call feedkeys(a:search_text)
endfunction

" leader + b to open buffer list with ctrlp
nmap <leader>b :CtrlPBuffer<CR>

" file finder mapping
let g:ctrlp_map = ',e'
let g:ctrlp_show_hidden = 1
let g:ctrlp_cmd = 'CtrlPMRU'

nmap ,g :CtrlPBufTag<CR>
nmap ,G :CtrlPBufTagAll<CR>
nmap ,f :CtrlPLine<CR>
nmap ,m :CtrlPMRUFiles<CR>
nmap ,c :CtrlPCmdPalette<CR>

" same as previous mappings, but calling with current word as default text
nmap ,wg :call CtrlPWithSearchText(expand('<cword>'), 'BufTag')<CR>
nmap ,wG :call CtrlPWithSearchText(expand('<cword>'), 'BufTagAll')<CR>
nmap ,wf :call CtrlPWithSearchText(expand('<cword>'), 'Line')<CR>
nmap ,we :call CtrlPWithSearchText(expand('<cword>'), '')<CR>
nmap ,pe :call CtrlPWithSearchText(expand('<cfile>'), '')<CR>
nmap ,wm :call CtrlPWithSearchText(expand('<cword>'), 'MRUFiles')<CR>
nmap ,wc :call CtrlPWithSearchText(expand('<cword>'), 'CmdPalette')<CR>

" don't change working directory
let g:ctrlp_working_path_mode = 0

" show list of errors and warnings on the current file
nmap <leader>e :Errors<CR>
let g:syntastic_check_on_open = 1
let g:syntastic_enable_signs = 0

" don't use linter, we use syntastic for that
let g:pymode_lint_on_write = 0
let g:pymode_lint_signs = 0

" don't fold python code on open

let g:neocomplcache_enable_camel_case_completion = 1
let g:neocomplcache_enable_camel_case_completion = 1
let g:neocomplcache_enable_underbar_completion = 1
let g:neocomplcache_fuzzy_completion_start_length = 1
let g:neocomplcache_auto_completion_start_length = 1
let g:neocomplcache_manual_completion_start_length = 1
let g:neocomplcache_min_keyword_length = 1
let g:neocomplcache_min_syntax_length = 1

" complete with workds from any opened file
let g:neocomplcache_same_filetype_lists = {}
let g:neocomplcache_same_filetype_lists._ = '_'

" mappings to toggle display, and to focus on it
let g:tabman_toggle = 'tl'
let g:tabman_focus  = 'tf'

" Fix to let ESC work as espected with Autoclose plugin
let g:AutoClosePumvisible = {"ENTER": "\<C-Y>", "ESC": "\<ESC>"}

" mappings to move blocks in 4 directions
vmap <expr> <S-M-LEFT> DVB_Drag('left')
vmap <expr> <S-M-RIGHT> DVB_Drag('right')
vmap <expr> <S-M-DOWN> DVB_Drag('down')
vmap <expr> <S-M-UP> DVB_Drag('up')
vmap <expr> D DVB_Duplicate()

" this first setting decides in which order try to guess your current vcs
" UPDATE it to reflect your preferences, it will speed up opening files
let g:signify_vcs_list = [ 'git', 'hg' ]

" mappings to jump to changed blocks
nmap <leader>sn <plug>(signify-next-hunk)
nmap <leader>sp <plug>(signify-prev-hunk)

" nicer colors
highlight DiffAdd           cterm=bold ctermbg=none ctermfg=119
highlight DiffDelete        cterm=bold ctermbg=none ctermfg=167
highlight DiffChange        cterm=bold ctermbg=none ctermfg=227
highlight SignifySignAdd    cterm=bold ctermbg=237  ctermfg=119
highlight SignifySignDelete cterm=bold ctermbg=237  ctermfg=167
highlight SignifySignChange cterm=bold ctermbg=237  ctermfg=227

" mapping
nmap  -  <Plug>(choosewin)

" show big letters
let g:choosewin_overlay_enable = 1

" airline
set ttimeoutlen=50
set noshowmode
set fillchars+=stl:\ ,stlnc:\

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif

let g:airline_theme = 'wombat'
let g:airline_powerline_fonts = 0
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#branch#empty_message = ''
let g:airline#extensions#whitespace#enabled = 0 
let g:airline#extensions#tabline#enabled = 1

" UltiSnips -------------------------------
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

let g:Powerline_symbols='fancy'
let g:Powerline_cache_enabled = 0
let g:user_emmet_leader_key='<C-e>' 
let g:acp_behaviorSnipmateLength = 1
let g:script_runner_key = '<F9>'
let g:unite_source_grep_recursive_opt = ''
let g:unite_source_grep_search_word_highlight=1

endif
