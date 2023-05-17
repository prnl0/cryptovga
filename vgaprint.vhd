library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vga_pack.all;

entity vgaprint is
  port (
    clk               : in std_logic;
    display           : in std_logic;
    col               : in natural range 0 to res_width - 1;
    row               : in natural range 0 to res_height - 1;
    red, green, blue  : out std_logic_vector(0 to 3)
  );
end vgaprint;

architecture arch of vgaprint is
begin
  print: process (clk, display, row, col)
    type glyph_char_map_t is array(character) of natural;
    
    constant glyph_char_map : glyph_char_map_t := (
      -- Miscellaneous symbols
      ' ' => 0, ':' => 1, ';' => 2, '.' => 3, '[' => 4, ']' => 5,
      -- Letters (lowercase)
      'a' =>  6, 'b' =>  7, 'c' =>  8, 'd' =>  9, 'e' => 10, 'f' => 11, 'g' => 12, 'h' => 13,
      'i' => 14, 'j' => 15, 'k' => 16, 'l' => 17, 'm' => 18, 'n' => 19, 'o' => 20, 'p' => 21,
      'q' => 22, 'r' => 23, 's' => 24, 't' => 25, 'u' => 26, 'v' => 27, 'w' => 28, 'x' => 29,
      'y' => 30, 'z' => 31,
      -- Letter (uppercase)
      'B' => 32, 'D' => 33, 'N' => 34,
      -- Numbers
      '0' => 35, '1' => 36, '2' => 37, '3' => 38, '4' => 39, '5' => 40, '6' => 41, '7' => 42,
      '8' => 43, '9' => 44,
      -- Undefined (treat as spaces)
      others => 0
    );
    constant glyphs : glyphs_t := (
      ( -- space
        "00000",
        "00000",
        "00000",
        "00000",
        "00000",
        "00000",
        "00000"
      ),
      ( -- :
        "00000",
        "01100",
        "00000",
        "00000",
        "01100",
        "00000",
        "00000"
      ),
      ( -- ;
        "00000",
        "01100",
        "00000",
        "00000",
        "01100",
        "11000",
        "00000"
      ),
      ( -- .
        "00000",
        "00000",
        "00000",
        "00000",
        "00000",
        "01100",
        "00000"
      ),
      ( -- [
        "01110",
        "01000",
        "01000",
        "01000",
        "01000",
        "01110",
        "00000"
      ),
      ( -- ]
        "11100",
        "00100",
        "00100",
        "00100",
        "00100",
        "11100",
        "00000"
      ),
      ( -- a
        "00000",
        "01100",
        "00010",
        "01110",
        "10010",
        "01110",
        "00000"
      ),
      ( -- b
        "10000",
        "10000",
        "11100",
        "10010",
        "10010",
        "11100",
        "00000"
      ),
      ( -- c
        "00000",
        "01100",
        "10010",
        "10000",
        "10010",
        "01100",
        "00000"
      ),
      ( -- d
        "00010",
        "00010",
        "01110",
        "10010",
        "10010",
        "01110",
        "00000"
      ),
      ( -- e
        "00000",
        "01100",
        "10010",
        "11110",
        "10000",
        "01110",
        "00000"
      ),
      ( -- f
        "00110",
        "01000",
        "11110",
        "01000",
        "01000",
        "01000",
        "00000"
      ),
      ( -- g
        "00000",
        "01110",
        "10010",
        "10010",
        "01110",
        "00010",
        "01100"
      ),
      ( -- h
        "10000",
        "10000",
        "11100",
        "10010",
        "10010",
        "10010",
        "00000"
      ),
      ( -- i
        "00100",
        "00000",
        "01100",
        "00100",
        "00100",
        "01110",
        "00000"
      ),
      ( -- j
        "00010",
        "00000",
        "00010",
        "00010",
        "00010",
        "10010",
        "01100"
      ),
      ( -- k
        "10000",
        "10010",
        "10100",
        "11000",
        "10100",
        "10010",
        "00000"
      ),
      ( -- l
        "01100",
        "00100",
        "00100",
        "00100",
        "00100",
        "01110",
        "00000"
      ),
      ( -- m
        "00000",
        "11110",
        "10101",
        "10101",
        "10101",
        "10101",
        "00000"
      ),
      ( -- n
        "00000",
        "11100",
        "10010",
        "10010",
        "10010",
        "10010",
        "00000"
      ),
      ( -- o
        "00000",
        "01100",
        "10010",
        "10010",
        "10010",
        "01100",
        "00000"
      ),
      ( -- p
        "00000",
        "11100",
        "10010",
        "10010",
        "11100",
        "10000",
        "10000"
      ),
      ( -- q
        "00000",
        "01110",
        "10010",
        "10010",
        "01110",
        "00010",
        "00010"
      ),
      ( -- r
        "00000",
        "10110",
        "11000",
        "10000",
        "10000",
        "10000",
        "00000"
      ),
      ( -- s
        "00000",
        "01110",
        "10000",
        "01100",
        "00010",
        "11100",
        "00000"
      ),
      ( -- t
        "01000",
        "01000",
        "11100",
        "01000",
        "01000",
        "00110",
        "00000"
      ),
      ( -- u
        "00000",
        "10010",
        "10010",
        "10010",
        "10010",
        "01110",
        "00000"
      ),
      ( -- v
        "00000",
        "10001",
        "10001",
        "01010",
        "01010",
        "00100",
        "00000"
      ),
      ( -- w
        "00000",
        "10101",
        "10101",
        "10101",
        "10101",
        "01110",
        "00000"
      ),
      ( -- x
        "00000",
        "10010",
        "10010",
        "01100",
        "10010",
        "10010",
        "00000"
      ),
      ( -- y
        "00000",
        "10010",
        "10010",
        "10010",
        "01110",
        "00010",
        "01100"
      ),
      ( -- z
        "00000",
        "11110",
        "00100",
        "01000",
        "10000",
        "11110",
        "00000"
      ),
      ( -- B
        "11100",
        "10010",
        "11100",
        "10010",
        "10010",
        "11100",
        "00000"
      ),
      ( -- D
        "11100",
        "10010",
        "10010",
        "10010",
        "10010",
        "11100",
        "00000"
      ),
      ( -- N
        "10010",
        "10010",
        "11010",
        "10110",
        "10010",
        "10010",
        "00000"
      ),
      ( -- 0
        "01100",
        "10010",
        "10110",
        "11010",
        "10010",
        "01100",
        "00000"
      ),
      ( -- 1
        "00100",
        "01100",
        "10100",
        "00100",
        "00100",
        "11110",
        "00000"
      ),
      ( -- 2
        "01100",
        "10010",
        "00100",
        "01000",
        "10000",
        "11110",
        "00000"
      ),
      ( -- 3
        "11100",
        "00010",
        "01100",
        "00010",
        "00010",
        "11100",
        "00000"
      ),
      ( -- 4
        "00010",
        "00110",
        "01010",
        "11110",
        "00010",
        "00010",
        "00000"
      ),
      ( -- 5
        "11110",
        "10000",
        "11100",
        "00010",
        "10010",
        "01100",
        "00000"
      ),
      ( -- 6
        "01100",
        "10000",
        "11100",
        "10010",
        "10010",
        "01100",
        "00000"
      ),
      ( -- 7
        "11110",
        "00010",
        "00010",
        "00100",
        "01000",
        "10000",
        "00000"
      ),
      ( -- 8
        "01100",
        "10010",
        "01100",
        "10010",
        "10010",
        "01100",
        "00000"
      ),
      ( -- 9
        "01100",
        "10010",
        "10010",
        "01110",
        "00010",
        "01100",
        "00000"
      )
    );
    
    variable cntr : natural := 0;
    variable col  : natural := 0;
    
    variable rel_col : natural := 0;
    variable rel_row : natural := 0;
    
    variable glyph      : glyph_t;
    variable glyph_row  : natural := 0;
    variable glyph_col  : natural := 0;
    
    variable buff_row_idx   : natural := 0;
    variable data_glyph_idx : natural := 1;
  begin
    if (rising_edge(clk)) then
      if (row = 0) then
        buff_row_idx := 0;
        glyph_row := 0;
      end if;
      
      if (display = '1') then
        cntr := cntr + 1;
        
        if (
          col >= display_region_beg(0) and col <= display_region_end(0)
          and row >= display_region_beg(1) and row <= display_region_end(1)
          and (display_region_end(0) - col + glyph_col) >= (glyph_dims(0) + glyph_spacing(0))
          and (display_region_end(1) - row + glyph_row) >= (glyph_dims(1) + glyph_spacing(1))
          and (cntr mod freq_ratio) = 0 -- FIXME: replace? (prevents data_glyph_idx from increasing twice as fast)
        ) then
          rel_col := col - display_region_beg(0);
          rel_row := row - display_region_beg(1);
          
          -- For whatever reason, modulo operator behaves strangely when rel_col/rel_row = 0, so we
          -- do this. Additionally, it appears Quartus 21.1 does not support the closest thing to a
          -- ternary operator in VHDL: q := value1 when condition else value2.
          if (rel_col /= 0) then
            glyph_col := rel_col mod (glyph_dims(0) + glyph_spacing(0));
          end if;
          
          if (rel_row /= 0) then
            glyph_row := rel_row mod (glyph_dims(1) + glyph_spacing(1));
          end if;
          
          if (glyph_row = 0 and rel_col = 0 and rel_row > 0) then
            buff_row_idx := buff_row_idx + 1;
          end if;
          
          if (glyph_col = 0) then
            if (rel_col > 0) then
              data_glyph_idx := data_glyph_idx + 1;
            end if;
            glyph := glyphs(glyph_char_map(buff(buff_row_idx)(data_glyph_idx)));
          end if;
          
          if (
            length_buff(buff_row_idx) /= 0
            and glyph_col /= glyph_dims(0) and glyph_row /= glyph_dims(1)
            and data_glyph_idx <= length_buff(buff_row_idx)
            and glyph(glyph_row)(glyph_col) = '1'
            and buff_row_idx = (rel_row / (glyph_dims(1) + glyph_spacing(0)))
          ) then
            red <= "1111";
            green <= "1111";
            blue <= "1111";
          else
            red <= "0000";
            green <= "0000";
            blue <= "0000";
          end if;
        else
          red <= "0000";
          green <= "0000";
          blue <= "0000";
        end if;
        
        if ((cntr mod freq_ratio) = 0) then
          col := col + 1;
        end if;
        
        if (cntr >= res_width * freq_ratio) then
          cntr := 0;
          col := 0;
          glyph_col := 0;
          data_glyph_idx := 1;
        end if;
      else
        red <= "0000";
        green <= "0000";
        blue <= "0000";
      end if;
    end if;
  end process print;
end arch;