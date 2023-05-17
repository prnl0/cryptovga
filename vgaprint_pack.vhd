library ieee;
use ieee.std_logic_1164.all;

package vgaprint_pack is
  type glyph_t is array (0 to 4) of std_logic_vector(0 to 3);
  type glyphs_t is array (0 to 2) of glyph_t;
end package vgaprint_pack;