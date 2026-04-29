return require('packer').startup(function()
  use 'wbthomason/packer.nvim' -- Package manager
  use 'chriskempson/base16-vim' -- Colours
  use "nvim-lua/plenary.nvim" -- All the lua functions I don't want to write twice.

  use {
      'junegunn/fzf',
      'junegunn/fzf.vim' -- fzf
  }
end)
