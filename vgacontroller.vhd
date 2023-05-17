library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vga_pack.all;

entity vgacontroller is
  port (
    vga_clk                       : in std_logic;
    vga_red, vga_green, vga_blue  : out std_logic_vector(0 to 3);
    vga_hsync, vga_vsync          : out std_logic
  );
end vgacontroller;

architecture arch of vgacontroller is
  component vgasync is
    port (
      clk                 : in std_logic;
      hsync, vsync        : out std_logic;
      display             : out std_logic;
      col                 : out natural range 0 to res_width - 1;
      row                 : buffer natural range 0 to res_height - 1
    );
  end component;
  
  component vgaprint is
    port (
      clk               : in std_logic;
      display           : in std_logic;
      col               : in natural range 0 to res_width - 1;
      row               : in natural range 0 to res_height - 1;
      red, green, blue  : out std_logic_vector(0 to 3)
    );
  end component;
  
  signal s_display  : std_logic := '0';
  signal s_col      : natural range 0 to res_width - 1 := 0;
  signal s_row      : natural range 0 to res_height - 1 := 0;
begin
  sync_map : vgasync port map (
    clk => vga_clk,
    hsync => vga_hsync, vsync => vga_vsync,
    display => s_display, row => s_row, col => s_col
  );
  print_map : vgaprint port map (
    clk => vga_clk,
    display => s_display, row => s_row, col => s_col,
    red => vga_red, green => vga_green, blue => vga_blue
  );
end arch;