library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vga_pack.all;

entity vgasync is
  port (
    clk                 : in std_logic;
    hsync, vsync        : out std_logic;
    display             : out std_logic;
    col                 : out natural range 0 to res_width - 1;
    row                 : buffer natural range 0 to res_height - 1
  );
end vgasync;

architecture arch of vgasync is
  -- Clock cycles
  constant h_sync_clocks  : natural := 96 * freq_ratio;
  constant h_bp_clocks    : natural := 48 * freq_ratio;
  constant h_data_clocks  : natural := res_width * freq_ratio;
  constant h_fp_clocks    : natural := 16 * freq_ratio;
  constant h_total_clocks : natural :=
    h_sync_clocks + h_bp_clocks + h_data_clocks + h_fp_clocks; -- no. of clock cycles per line
  constant h_max_clocks   : natural := h_data_clocks;
  
  constant v_sync_clocks  : natural := 2 * h_total_clocks;
  constant v_bp_clocks    : natural := 33 * h_total_clocks;
  constant v_data_clocks  : natural := res_height * h_total_clocks;
  constant v_fp_clocks    : natural := 10 * h_total_clocks;
  constant v_total_clocks : natural :=
    v_sync_clocks + v_bp_clocks + v_data_clocks + v_fp_clocks; -- no. of clock cycles per line
  constant v_max_clocks   : natural := v_data_clocks;

  -- System states
  type state_t is (s_sync, s_back_porch, s_display, s_front_porch);
  type state_map_integ_t is array (state_t) of integer;
  type state_map_logic_t is array (state_t) of std_logic;
  type state_map_state_t is array (state_t) of state_t;
  
  constant sync_values    : state_map_logic_t := (s_sync => '0', others => '1');
  constant display_values : state_map_logic_t := (s_display => '1', others => '0');
  constant next_states    : state_map_state_t := (s_back_porch, s_display, s_front_porch, s_sync);
  
  signal vsync_done : std_logic := '0';
  
  signal hdisplay, vdisplay : std_logic := '0';
begin
  horizontal_sync : process (clk, vsync_done)
    constant timeouts : state_map_integ_t := (
      h_sync_clocks, h_bp_clocks, h_data_clocks, h_fp_clocks
    );
  
    variable state    : state_t := s_sync;
    variable timeout  : natural range 0 to h_max_clocks := 0;
    variable cntr     : natural range 0 to h_max_clocks - 1 := 0;
  begin
    if (rising_edge(clk)) then
        cntr := cntr + 1;
        if (cntr = timeout) then
          hsync <= sync_values(state);
          timeout := timeouts(state);
          hdisplay <= display_values(state);
          
          if (state = s_display and vdisplay = '1') then
            row <= row + 1;
          end if;
          
          if (vsync_done = '1') then
            row <= 0;
          end if;
          
          state := next_states(state);
          cntr := 0;
        end if;
    end if;
  end process horizontal_sync;
  
  vertical_sync : process (clk)
    constant timeouts : state_map_integ_t := (
      v_sync_clocks, v_bp_clocks, v_data_clocks, v_fp_clocks
    );
    
    variable state    : state_t := s_sync;
    variable timeout  : natural range 0 to v_max_clocks := 0;
    variable cntr     : natural range 0 to v_max_clocks - 1 := 0;
  begin
    if (rising_edge(clk)) then
        cntr := cntr + 1;
        if (cntr = timeout) then
          vsync <= sync_values(state);
          vdisplay <= 
          display_values(state);
          timeout := timeouts(state);
          if (state = s_sync) then
            vsync_done <= '1';
          else
            vsync_done <= '0';
          end if;
          state := next_states(state);
          cntr := 0;
        end if;
    end if;
  end process vertical_sync;
  
  track_display_state: process (clk, hdisplay, vdisplay)
  begin
    if (rising_edge(clk)) then
      display <= hdisplay and vdisplay;
    end if;
  end process track_display_state;
end arch;