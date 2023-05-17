library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sha_256_pkg.all; -- remove
use work.utils_pkg.all;
use work.crypto_package.all;
use work.vga_pack.all;

entity cryptovga is
  port (
    g_clk                   : in std_logic;
    g_red, g_green, g_blue  : out std_logic_vector(0 to 3);
    g_hsync, g_vsync        : out std_logic
  );
end cryptovga;

architecture arch of cryptovga is
  component vgacontroller is
    port (
      vga_clk                       : in std_logic;
      vga_red, vga_green, vga_blue  : out std_logic_vector(0 to 3);
      vga_hsync, vga_vsync          : out std_logic
    );
  end component;
  
  component crypto is
    port (
      crypto_clk          : in std_logic;
      crypto_digest       : buffer std_logic_vector((WORD_SIZE * 8) - 1 downto 0);
      crypto_finished     : buffer std_logic;
      crypto_block_found  : buffer std_logic;
      crypto_block        : buffer block_t
    );
  end component;
  
  signal hashing_finished : std_logic := '0';
  signal block_found      : std_logic := '0';
  signal curr_block       : block_t;
begin
  main: process (g_clk)
    type char_map_t is array (0 to 15) of character;
    constant char_map : char_map_t := (
       0 => '0',  1 => '1',  2 => '2',  3 => '3',  4 => '4',  5 => '5',  6 => '6', 7 => '7', 8 => '8',
       9 => '9', 10 => 'a', 11 => 'b', 12 => 'c', 13 => 'd', 14 => 'e', 15 => 'f'
    );
    variable temp : unsigned((WORD_SIZE * 8)-1 downto 0);
    variable str : string(1 to 63) := (others => ' ');
    variable printed : std_logic := '0';
  begin
    if (rising_edge(g_clk)) then
      if (hashing_finished = '1' and printed = '0') then
        str(1 to 4) := "[B: ";
        str(5 to 9) := nat_to_str(to_integer(curr_block.index + 1), 5);
        str(10 to 14) := "; D: ";
        str(15 to 16) := nat_to_str(to_integer(curr_block.difficulty), 2);
        str(17 to 21) := "; N: ";
        str(22 to 27) := nat_to_str(to_integer(curr_block.nonce), 6);
        str(28 to 31) := "] 0x";
        temp := unsigned(curr_block.hash);
        for i in 1 to 32 loop
          str(63 - i + 1) := char_map(to_integer(temp((4*i-1) downto 4*(i-1))));
        end loop;
        print(str);
        printed := '1';
      elsif (hashing_finished = '0' and printed = '1') then
        printed := '0';
      end if;
    end if;
  end process main;
  
  miner : crypto port map (
    crypto_clk          => g_clk,
    crypto_finished     => hashing_finished,
    crypto_block_found  => block_found,
    crypto_block        => curr_block
  );
  vga_controller : vgacontroller port map (
    vga_clk   => g_clk,
    vga_red   => g_red,
    vga_green => g_green,
    vga_blue  => g_blue,
    vga_hsync => g_hsync,
    vga_vsync => g_vsync
  );
end arch;