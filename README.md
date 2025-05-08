# bufferback.nvim

Restore closed buffers in the same way you restore closed tabs in your favourite browser.

## In Action

TODO: add recording

## Installation

Using Lazy:

```lua
{
  'mattpatterson94/bufferback.nvim',
  opts = {
    max_stack_size = 20,
    keymaps = {
      delete_buffer = "<S-w>",
      restore_buffer = "<S-M-w>",
      list_stack = "<leader>bL",
    }
  }
}
```

## Usage

### Commands

```lua
-- Restore the most recently deleted buffer
:BufferBack
-- See a list of all the deleted buffers in the stack
:BufferBackList
-- Delete a buffer
:BufferBackDelete 
```

### Default keymap

```lua
<S-w> - Delete buffer
<S-M-w> - Restore buffer
<leader>bL - See deleted buffers
```
