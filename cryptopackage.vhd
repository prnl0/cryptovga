library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sha_256_pkg.all;

package crypto_package is
  -- In cycles/hash; hash_rate / board_freq => s/hash
  constant hash_rate : natural := 1000;
  -- No. of cycles to wait after successfully mining a block before resuming operations.
  constant timeout_after_mine : natural := 5000;
  
  -- We only send one block of data to hash, so
  --   bits_per_index + bp_hash + bp_timestamp + bp_data + bp_difficulty + bp_nonce
  -- must be = 16 * WORD_SIZE. Assuming that WORD_SIZE = 32, the sum must be = 16 * 32 = 512 bits.
  constant bits_per_block       : natural                 := 16 * WORD_SIZE; -- DO NOT ALTER
  constant bits_per_index       : natural range 1 to 32   := 32;
  constant bits_per_hash        : natural range 1 to 256  := 8 * WORD_SIZE; -- DO NOT ALTER
  constant bits_per_timestamp   : natural range 1 to 32   := 32;
  constant bits_per_difficulty  : natural range 1 to 32   := 7;
  constant bits_per_nonce       : natural range 1 to 32   := 32;
  constant bits_per_data        : natural range 1 to 512  := 153;
  
  constant block_generation_interval      : natural range 0 to 50 := 10; -- in seconds
  constant difficulty_adjustment_interval : natural range 0 to 50 := 10; -- in blocks
  constant expected_time                  : unsigned(bits_per_timestamp - 1 downto 0) :=
    to_unsigned(block_generation_interval * difficulty_adjustment_interval, bits_per_timestamp);
  
  type block_t is record
    index       : unsigned(bits_per_index - 1 downto 0);
    hash        : std_logic_vector(bits_per_hash - 1 downto 0);
    prev_hash   : std_logic_vector(bits_per_hash - 1 downto 0);
    timestamp   : unsigned(bits_per_timestamp - 1 downto 0);
    data        : std_logic_vector(0 to bits_per_data - 1);
    difficulty  : unsigned(bits_per_difficulty - 1 downto 0);
    nonce       : unsigned(bits_per_nonce - 1 downto 0);
  end record block_t;
  type prev_adj_blocks_t is array (0 to 1) of block_t;

  shared variable crypto_reset      : std_logic := '0';
  shared variable crypto_ready      : std_logic := '0';
  shared variable crypto_nblocks    : natural := 0;
  shared variable crypto_block_in   : std_logic_vector(0 to bits_per_block - 1);
  shared variable crypto_digest     : std_logic_vector(bits_per_hash - 1 downto 0);
  shared variable crypto_timestamp  : unsigned(bits_per_timestamp - 1 downto 0) := (others => '0');
  
  constant genesis : block_t := (
    index       => (others => '0'),
    -- Chosen at random; does not necessarily match the actual hash of the genesis block.
    hash        => (0 to bits_per_hash - 1 => '1', others => '0'),
    prev_hash   => (others => '0'),
    timestamp   => (others => '0'),
    data        => (0 to bits_per_data / 2 => '0', others => '1'),
    difficulty  => (0 => '1', others => '0'),
    nonce       => (others => '0')
  );
  shared variable latest_block    : block_t := genesis;
  shared variable prev_adj_blocks : prev_adj_blocks_t := (genesis, genesis);
  
  procedure generate_block(
    signal in_data    : out std_logic_vector(0 to bits_per_block - 1);
    signal block_out  : inout block_t;
           nonce      : unsigned(bits_per_nonce - 1 downto 0)
  );
  
  function get_difficulty return unsigned;
  function get_adjusted_difficulty return unsigned;
  
  procedure generate_hash(
    signal in_data    : out std_logic_vector(0 to bits_per_block - 1);
           id         :     unsigned(bits_per_index - 1 downto 0);
           prev_hash  :     std_logic_vector(bits_per_hash - 1 downto 0);
           timestamp  :     unsigned(bits_per_timestamp - 1 downto 0);
           data       :     std_logic_vector(0 to bits_per_data - 1);
           difficulty :     unsigned(bits_per_difficulty - 1 downto 0);
           nonce      :     unsigned(bits_per_nonce - 1 downto 0)
  );
  function hash_matches_difficulty (
    hash        : std_logic_vector(bits_per_hash - 1 downto 0);
    difficulty  : unsigned(bits_per_difficulty - 1 downto 0)
  ) return std_logic;
end package crypto_package;

package body crypto_package is
  procedure generate_block(
    signal in_data    : out std_logic_vector(0 to bits_per_block - 1);
    signal block_out  : inout block_t;
           nonce      : unsigned(bits_per_nonce - 1 downto 0)
  ) is
  begin
    block_out.index       <= latest_block.index + 1;
    block_out.hash        <= (others => '0');
    block_out.prev_hash   <= latest_block.hash;
    block_out.timestamp   <= crypto_timestamp;
    block_out.data        <= (others => '0');
    block_out.difficulty  <= get_difficulty;
    block_out.nonce       <= nonce;
    generate_hash(
      in_data,
      block_out.index, block_out.prev_hash, block_out.timestamp,
      block_out.data, block_out.difficulty, block_out.nonce
    );
  end procedure generate_block;
  
  function get_difficulty return unsigned is
  begin
    if (
      latest_block.index /= 0
      and (latest_block.index mod difficulty_adjustment_interval) = 0
    ) then
      return get_adjusted_difficulty;
    else
      return latest_block.difficulty;
    end if;
  end function get_difficulty;
  
  function get_adjusted_difficulty return unsigned is
    variable prev_adj_block : block_t;
    variable time_taken     : unsigned(bits_per_timestamp - 1 downto 0) := (others => '0');
  begin
    prev_adj_block := prev_adj_blocks(0);
    time_taken := latest_block.timestamp - prev_adj_block.timestamp;
    if (time_taken < (expected_time / 2)) then
      return prev_adj_block.difficulty + 1;
    elsif (time_taken > (expected_time * 2)) then
      return prev_adj_block.difficulty - 1;
    else
      return prev_adj_block.difficulty;
    end if;
  end function get_adjusted_difficulty;
  
  procedure generate_hash(
    signal in_data    : out std_logic_vector(0 to bits_per_block - 1);
           id         :     unsigned(bits_per_index - 1 downto 0);
           prev_hash  :     std_logic_vector(bits_per_hash - 1 downto 0);
           timestamp  :     unsigned(bits_per_timestamp - 1 downto 0);
           data       :     std_logic_vector(0 to bits_per_data - 1);
           difficulty :     unsigned(bits_per_difficulty - 1 downto 0);
           nonce      :     unsigned(bits_per_nonce - 1 downto 0)
  ) is
    variable input : std_logic_vector(0 to bits_per_block - 1);
  begin
    input(0 to 31) := std_logic_vector(id);
    input(32 to 287) := prev_hash;
    input(288 to 319) := std_logic_vector(timestamp);
    input(320 to 326) := std_logic_vector(difficulty);
    input(327 to 358) := std_logic_vector(nonce);
    input(359 to 511) := data;
    crypto_ready := '1';
    crypto_reset := '1'; -- stop reset
    crypto_nblocks := 1;
    in_data <= input;
  end procedure generate_hash;
  
  function hash_matches_difficulty (
    hash        : std_logic_vector(bits_per_hash - 1 downto 0);
    difficulty  : unsigned(bits_per_difficulty - 1 downto 0)
  ) return std_logic is
    variable zero_cnt : unsigned(bits_per_difficulty - 1 downto 0) := (others => '0');
  begin
    for i in bits_per_hash - 1 downto 128 loop
      if (hash(i) = '0') then
        zero_cnt := zero_cnt + 1;
      else
        exit;
      end if;
    end loop;
    if (zero_cnt >= difficulty) then
      return '1';
    else
      return '0';
    end if;
  end function hash_matches_difficulty;
end package body crypto_package;