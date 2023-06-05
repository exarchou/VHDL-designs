-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- Entity
entity reg_fifo_no_flags is
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
end reg_fifo_no_flags;


-- Architecture
architecture rtl of reg_fifo_no_flags is

    type t_FIFO_DATA is array (0 to g_DEPTH-1) of std_logic_vector(g_WIDTH-1 downto 0);
    signal r_FIFO_DATA : t_FIFO_DATA := (others => (others => '0'));

    signal r_WR_INDEX : integer range 0 to g_DEPTH-1 := 0;
    signal r_RD_INDEX : integer range 0 to g_DEPTH-1 := 0;

    signal r_FIFO_COUNT : integer range -1 to g_DEPTH+1 := 0;

    signal w_FULL  : std_logic;
    signal w_EMPTY : std_logic;

begin

    p_CONTROL : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if i_rst_sync = '1' then
                r_FIFO_COUNT <= 0;
                r_WR_INDEX   <= 0;
                r_RD_INDEX   <= 0;
            else
                -- Calculate total words
                if (i_wr_en = '1' and i_rd_en = '0') then
                    r_FIFO_COUNT <= r_FIFO_COUNT + 1;
                elsif (i_wr_en = '0' and i_rd_en = '1') then
                    r_FIFO_COUNT <= r_FIFO_COUNT - 1;
                end if;

                -- Calculate write index
                if (i_wr_en = '1' and w_FULL = '0') then
                    if r_WR_INDEX < g_DEPTH-1 then
                        r_WR_INDEX <= r_WR_INDEX + 1
                    else -- Round buffer
                        r_WR_INDEX <= 0;
                end if

                -- Calculate write index
                if (i_rd_en = '1' and w_EMPTY = '0') then
                    if r_RD_INDEX < g_DEPTH-1 then
                        r_RD_INDEX <= r_RD_INDEX + 1
                    else
                        r_RD_INDEX <= 0;
                end if

                -- Write command
                if (i_wr_en = '1') then
                    if  (w_FULL = '0') then
                        r_FIFO_DATA(r_WR_INDEX) <= i_wr_data;
                    else
                        report "FIFO FULL!";
                    end if;
                end if

                -- READ command
                if (i_rd_en = '1') then
                    if  (w_EMPTY = '0') then
                        o_rd_data <= r_FIFO_DATA(r_RD_INDEX)
                    else
                        report "FIFO EMPTY!";
                    end if;

                end if

            end if;

        end if;

    end process p_CONTROL;

    -- Combinational logic
    w_FULL  <= '1' when r_FIFO_COUNT = g_DEPTH else '0';
    W_EMPTY <= '1' when r_FIFO_COUNT = 0 else '0';

    o_full  <= w_FULL;
    o_empty <= w_EMPTY;

end rtl;
