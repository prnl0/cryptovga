library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sha_256_pkg.all;
use work.crypto_package.all;
use work.vga_pack.all;

entity crypto is
  port (
    crypto_clk          : in std_logic;
    crypto_digest       : buffer std_logic_vector(bits_per_hash - 1 downto 0);
    crypto_finished     : buffer std_logic;
    crypto_block_found  : buffer std_logic;
    crypto_block        : buffer block_t
  );
end crypto;

architecture arch of crypto is
  component sha_256_core is
    port (
      clk           : in std_logic;
      rst           : in std_logic;
      data_ready    : in std_logic;
      n_blocks      : in natural;
      msg_block_in  : in std_logic_vector(0 to bits_per_block - 1);
      finished      : out std_logic;
      data_out      : out std_logic_vector(bits_per_hash - 1 downto 0)
    );
  end component;
  
  component vgacontroller is
    port (
      vga_clk                       : in std_logic;
      vga_red, vga_green, vga_blue  : out std_logic_vector(0 to 3);
      vga_hsync, vga_vsync          : out std_logic
    );
  end component;
  
  signal in_data    : std_logic_vector(0 to bits_per_block - 1);
  signal block_out  : block_t;
  signal nonce      : unsigned(bits_per_nonce - 1 downto 0) := (others => '0');
begin
  main: process (crypto_clk)
    variable cnt  : natural := 0;
    variable cnt2 : natural := 0;
  begin
    if (rising_edge(crypto_clk)) then
      if (cnt2 = board_freq) then
        crypto_timestamp := crypto_timestamp + 1;
        cnt2 := 0;
      end if;
      
      if (crypto_block_found = '0' or cnt = hash_rate + timeout_after_mine) then
        if (crypto_finished = '1') then
          block_out.hash <= crypto_digest;
        end if;
        
        if (cnt = hash_rate / 2) then
          if (
            crypto_finished = '1'
            and hash_matches_difficulty(crypto_digest, block_out.difficulty) = '1'
          ) then
            latest_block := block_out;
            if ((block_out.index mod difficulty_adjustment_interval) = 0) then
              prev_adj_blocks(0) := prev_adj_blocks(1);
              prev_adj_blocks(1) := block_out;
            end if;
            nonce <= (others => '0');
            crypto_block_found <= '1';
          end if;
          crypto_ready := '0';
          crypto_reset := '0';
        end if;
        if (cnt >= hash_rate) then
          crypto_block_found <= '0';
          generate_block(in_data, block_out, nonce);
          crypto_block <= block_out;
          nonce <= nonce + 1;
          cnt := 0;
        end if;
      end if;
      
      cnt := cnt + 1;
      cnt2 := cnt2 + 1;
    end if;
  end process main;
  
  sha256: sha_256_core port map (
    clk           => crypto_clk,
    rst           => crypto_reset,
    data_ready    => crypto_ready,
    n_blocks      => crypto_nblocks,
    msg_block_in  => in_data,
    finished      => crypto_finished,
    data_out      => crypto_digest
  );
end arch;