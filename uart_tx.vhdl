-- UART Transceiver
-- 8 bits of serial data, one start bit, one stop bit and no parity bit
-- The receiver is made to work at 115200 baud rate with a 10MHz clock
-- g_CLKS_PER_BIT = 10000000 / 115200 = 87


-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- Entity
entity uart_tx is
    generic (
        g_CLKS_PER_BIT := 87
    );
    port (
        i_clk       : in  std_logic;
        i_tx_dv     : in  std_logic;
        i_tx_byte   : in  std_logic_vector(7 downto 0)
        o_tx_enable : out std_logic;
        o_tx_serial : out std_logic;
        o_tx_done   : out std_logic
    );
end uart_tx;


-- Architecture
architecture rtl of uart_tx is

    type t_SM is (s_Idle, s_TX_Start_Bit, s_TX_Data_Bits, s_TX_Stop_Bit, s_Cleanup);
    signal r_SM : t_SM := s_Idle;
    signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
    signal r_Bit_Index : integer range 0 to 7 := 0;
    signal r_TX_Byte   : std_logic_vector(7 downto 0) := (others => '0');
    signal r_TX_Done   : std_logic := '0';

begin

    -- Control State Machine TX
    p_UART_TX : process (i_clk)
    begin
        if rising_edge(i_clk) then

            case r_SM is

                when s_Idle =>
                    o_tx_enable <= 0;
                    o_tx_serial <= '1';
                    r_Clk_Count <= 0;
                    r_Bit_Index <= 0;
                    r_TX_Done   <= '0';
                    if i_tx_dv = '1' then
                        r_TX_Byte <= i_tx_byte;
                        r_SM <= s_TX_Start_Bit;
                    end if;

                when s_TX_Start_Bit =>
                    if r_Clk_Count = g_CLKS_PER_BIT-1 then
                        r_Clk_Count <= 0;
                        r_SM <= s_TX_Data_Bits;
                    else
                        r_Clk_Count <= r_Clk_Count + 1;
                        o_tx_serial <= '0';
                        o_tx_enable <= '1';
                    end if;

                when s_TX_Data_Bits =>
                    if r_Bit_Index < 8 then 
                        if r_Clk_Count = g_CLKS_PER_BIT-1 then
                            o_tx_serial <= r_TX_Byte(r_Bit_Index);
                            r_Bit_Index <= r_Bit_Index + 1
                            r_Clk_Count <= 0;
                        else
                            r_Clk_Count <= r_Clk_Count + 1;
                        end if;
                    else 
                        r_SM <= s_TX_Stop_Bit;
                    end if;
                    
                when s_TX_Stop_Bit =>
                    if r_Clk_Count = g_CLKS_PER_BIT-1 then
                        r_Clk_Count <= 0;
                        r_SM <= s_Cleanup;         
                    else
                        r_Clk_Count <= r_Clk_Count + 1;
                        o_tx_serial <= '1';
                    end if;
                    
                when s_Cleanup =>
                    r_SM <= s_Idle;
                    r_TX_Done <= '1';
                
                end case;

        end if;
    end process p_UART_TX;

    o_tx_done  <= r_TX_Done;


end rtl;
