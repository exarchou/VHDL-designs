-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- Entity
entity reg_fifo_no_flag_tb is
end reg_fifo_no_flag_tb;


-- Architecture
architecture sim of reg_fifo_no_flag_tb is

    constant : c_WIDTH : integer := 8;
    constant : c_DEPTH : integer := 32;

    signal r_RST_SYNC : std_logic := '0';
    signal r_CLK      : std_logic := '0';
    signal r_WR_EN    : std_logic := '0';
    signal r_WR_DATA  : std_logic_vector(c_WIDTH-1 downto 0) := (others => '0');
    signal w_FULL     : std_logic;
    signal r_RD_EN    : std_logic := '0';
    signal w_RD_DATA  : std_logic_vector(c_WIDTH-1 downto 0);
    signal w_EMPTY    : std_logic;

    component reg_fifo_no_flags is
        generic (
            g_WIDTH : integer := 8;
            g_DEPTH : integer := 32
        );
        port (
            i_rst_sync : in std_logic;
            i_clk      : in std_logic;
    
            -- FIFO Write Interface
            i_wr_en   : in  std_logic;
            i_wr_data : in  std_logic_vector(g_WIDTH-1 downto 0);
            o_full    : out std_logic;
    
            -- FIFO Read Interface
            i_rd_en   : in  std_logic;
            o_rd_data : out std_logic_vector(g_WIDTH-1 downto 0);
            o_empty   : out std_logic
        );
        end component reg_fifo_no_flags;
        
begin

    -- Initialize UUT
    UUT : reg_fifo_no_flags
        generic map (
            g_WIDTH => c_WIDTH,
            g_DEPTH => c_DEPTH
        );
        port map (
            i_rst_sync => r_RST_SYNC,
            i_clk      => r_CLK,
            i_wr_en    => r_WR_EN,
            i_wr_data  => r_WR_DATA,
            o_full     => w_FULL,
            i_rd_en    => r_RD_EN,
            o_rd_data  => w_RD_DATA,
            o_empty    => w_EMPTY
        );

    -- Generate CLK
    r_CLK <= not (r_CLK) after 10 ns;

    -- Main behavior
    process is
    begin
        wait for 20 ns;
        r_RST_SYNC <= '1';
        wait for 20 ns;
        r_RST_SYNC <= '0';
        wait for 20 ns;
        r_WR_DATA <= x"AA";
        r_WR_EN   <= '1';
        wait for 20 ns;
        r_WR_EN   <= '0';
        r_RD_EN   <= '1'; 
        report w_RD_DATA; 
        wait for 20 ns;
        r_WR_EN   <= '0';
        r_RD_EN   <= '1'; 
        report w_RD_DATA;  

    end process;

end sim;
