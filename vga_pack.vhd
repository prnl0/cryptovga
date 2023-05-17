library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package vga_pack is
  -- Common
  type vector_2d is array (0 to 1) of natural;
  
  -- Do not adjust
  constant res_width  : natural := 640;
  constant res_height : natural := 480;
  
  -- Used by synchronization and printing facilities
  constant board_freq : natural := 50000000; -- 50 MHz
  constant vga_freq   : natural := 25000000; -- 25 MHz (pixel clock frequency)
  constant freq_ratio : natural := board_freq / vga_freq;
  
  -- Used by printing facilities and controller
  constant display_region_beg   : vector_2d := (res_width / 2 - 195, res_height / 2 - 50); -- (x, y)
  constant display_region_end   : vector_2d := (res_width / 2 + 195, res_height / 2 + 50); -- (x, y)
  constant display_region_dims  : vector_2d := (
    display_region_end(0) - display_region_beg(0),
    display_region_end(1) - display_region_beg(1)
  );
  
  constant glyph_count    : natural := 45; -- 26 letters (+ 3 uppercase) + 10 digits + 6 misc. symbols
  constant glyph_dims     : vector_2d := (5, 7); -- in pixels (width, height)
  constant glyph_spacing  : vector_2d := (1, 1); -- in pixels (horizontal, vertical)
  constant max_glyphs_per_dim : vector_2d := (
    display_region_dims(0) / (glyph_dims(0) + glyph_spacing(0)) - 1,
    display_region_dims(1) / (glyph_dims(1) + glyph_spacing(1))
  );
  
  -- Do not adjust
  type buffer_t is array (0 to max_glyphs_per_dim(1) - 1) of string(1 to max_glyphs_per_dim(0));
  type length_buffer_t is array (0 to max_glyphs_per_dim(1) - 1) of
    natural range 0 to max_glyphs_per_dim(0);
  type glyph_t is array (0 to glyph_dims(1) - 1) of std_logic_vector(0 to glyph_dims(0) - 1);
  type glyphs_t is array (0 to glyph_count - 1) of glyph_t;
  
  -- Common
  shared variable buff        : buffer_t;
  shared variable length_buff : length_buffer_t;
  shared variable buff_row    : natural := 0;

  procedure print(data : in string);
end package vga_pack;

package body vga_pack is
  procedure print(data : in string) is
    variable padded_data : string(1 to max_glyphs_per_dim(0));
  begin
    if (buff_row = 0) then
      for i in 0 to max_glyphs_per_dim(1) - 1 loop
        length_buff(i) := 0;
      end loop;
    elsif (buff_row = max_glyphs_per_dim(1)) then
      for i in 0 to max_glyphs_per_dim(1) - 2 loop
        buff(i) := buff(i + 1);
        length_buff(i) := length_buff(i + 1);
      end loop;
      buff_row := buff_row - 1;
    end if;
    
    -- FIXME: calling the function too frequently causes padded_data to be overwritten
    -- many times with different input data. This produces garbage output on the display.
    if (data'length < max_glyphs_per_dim(0)) then
      for i in 1 to data'length loop
        padded_data(i) := data(i);
      end loop;
      for i in data'length + 1 to max_glyphs_per_dim(0) loop
        padded_data(i) := ' ';
      end loop;
    else
      padded_data := data; -- trims any additional chars (?)
    end if;
    
    buff(buff_row) := padded_data;
    length_buff(buff_row) := data'length;
    buff_row := buff_row + 1;
  end procedure print;
end package body vga_pack;