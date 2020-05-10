" Vim settings
"
"

" Configuration file for vim
set modelines=0     " CVE-2007-2438
set backspace=2     " more powerful backspacing
set autoindent      " enable autoinident

" not compatible with the old-fashion vi mode
set nocompatible

set guifont=Monaco\ for\ Powerline:h16

" allow plugins by file type (required for plugins!)
filetype plugin on
filetype indent on

" Fast saving
nmap <leader>w :w!<cr>
nmap <leader>W :W<cr>

" :W sudo saves the file
" STOP EDITING RO FILES WITHOUT SUDO!!!!!!!
command! W execute 'w !sudo tee % > /dev/null' <bar> edit!


" Ignore compiled files
set wildignore=*.o,*~,*.pyc
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

" Basic settings
set wildmenu
set cmdheight=1
set showmatch
set smarttab
set tabstop=4
set showmode
set cursorline
set expandtab
set ttyfast
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

" tab navigation mappings
map tn :tabn<CR>
map tp :tabp<CR>
map tt :tabnew<CR>
map ts :tab split<CR>

set completeopt-=preview


" Plugins
"
"


" Plugin installation
"

call plug#begin('~/.vim/plugged')

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'preservim/nerdtree'
Plug 'editorconfig/editorconfig-vim'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'dense-analysis/ale'
Plug 'mileszs/ack.vim'
Plug 'tpope/vim-surround'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-fugitive'
Plug 'davidhalter/jedi-vim', { 'for': 'python'}
" Deoplete
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
Plug 'deoplete-plugins/deoplete-jedi', { 'for': 'python'}
Plug 'easymotion/vim-easymotion'
Plug 'mattn/emmet-vim'
Plug 'gregsexton/MatchTag'
Plug 'xuhdev/SingleCompile'
Plug 'ironcamel/vim-script-runner'
Plug 'l4ys/molokai'

call plug#end()


" Plugin settings
"
"

" NERDtree
" F1 to open NERDtree
map <F10> :NERDTreeToggle<CR>

" molokai
let g:molokai_original = 1
colorscheme molokai

" vim-airline
" Set formatter to unique_tail_improved
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme = 'luna'
let g:airline_powerline_fonts = 1

" for ale
let g:airline#extensions#ale#enabled = 1
let airline#extensions#ale#error_symbol = '⌽ '
let airline#extensions#ale#warning_symbol = '⌽ '
let g:ale_echo_msg_error_str = 'Error'
let g:ale_echo_msg_warning_str = 'Warning'
let g:ale_echo_msg_format = '[%linter%][%severity%] %s'

" editorconfig
" Exclude fugitive and scp
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']


" ultisnips
" Set trigger key
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<S-tab>"
" Vertical split when do ultisnipedit
let g:UltiSnipsEditSplit="vertical"

" ale
let g:ale_sign_column_always = 1
let g:ale_linters = {
\   'javascript': ['eslint'],
\   'c': ['clang'],
\   'cpp': ['clang'],
\   'python': ['pylint']
\}
let g:ale_sign_error = '⌽ '
let g:ale_sign_warning = '⌽ '
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_enter = 0
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1


" ack.vim
if executable('ag')
    let g:ackprg = 'ag --vim-grep'
endif

" jedi-vim
let g:jedi#completions_enabled = 0

" deoplete
let g:deoplete#enable_at_startup = 1

" emmet-vim
let g:user_emmet_leader_key='<C-e>'

" tagbar
nmap <F9> :TagbarToggle<CR>
let g:tagbar_autofoucs = 1

" singlecompile
nmap <F11> :SCCompileRun<cr>

" vim-script-runner
let g:script_runner_key = '<F12>'