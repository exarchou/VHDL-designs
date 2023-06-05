-- UART Receiver
-- 8 bits of serial data, one start bit, one stop bit and no parity bit
-- The receiver is made to work at 115200 baud rate with a 10MHz clock
-- g_CLKS_PER_BIT = 10000000 / 115200 = 87


-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- Entity
entity uart_rx is
    generic (
        g_CLKS_PER_BIT := 87
    );
    port (
        i_clk       : in  std_logic;
        i_rx_serial : in  std_logic;
        o_rx_dv     : out std_logic;
        o_rx_byte   : out std_logic_vector(7 downto 0)
    );
end uart_rx;


-- Architecture
architecture rtl of uart_rx is

    type t_SM is (s_Idle, s_RX_Start_Bit, s_RX_Data_Bits, s_RX_Stop_Bit, s_Cleanup);
    signal r_SM : t_SM := s_Idle;
    signal r_RX_Data_R : std_logic := '0';
    signal r_RX_Data   : std_logic := '0';
    signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
    signal r_Bit_Index : integer range 0 to 7 := 0;
    signal r_RX_Byte   : std_logic_vector(7 downto 0) := (others => '0');
    signal r_RX_DV     : std_logic := '0';

begin

    -- Double register the incoming data to mitigate metastability
    p_SAMPLE : process (i_clk)
    begin
        if rising_edge(i_clk) then
            r_RX_Data_R <= i_rx_serial;
            r_RX_Data   <= r_RX_Data_R;
        end if;
    end process p_SAMPLE;

    -- Control State Machine RX
    p_UART_RX : process (i_clk)
    begin
        if rising_edge(i_clk) then

            case r_SM is

                when s_Idle =>
                    r_RX_DV <= '0';
                    r_Clk_Count <= 0;
                    r_Bit_Index <= 0;
                    if RX_Data = '0' then -- Start bit detection
                        r_SM <= s_RX_Start_Bit;
                    end if;
                
                when s_RX_Start_Bit =>
                    if r_Clk_Count = (g_CLKS_PER_BIT-1)/2 then
                        if r_RX_Data = '0' then -- Check if the start bit is still zero after half period time
                            r_SM <= s_RX_Data_Bits
                            r_Clk_Count <= 0;
                        else
                            r_SM <= s_Idle;
                        end if;
                    else
                        r_Clk_Count <= r_Clk_Count + 1;
                    end if;

                when s_RX_Data_Bits =>
                    if r_Bit_Index < 8 then
                        if r_Clk_Count = g_CLKS_PER_BIT-1 then
                            r_RX_Byte(r_Bit_Index) <= r_RX_Data;
                            r_Bit_Index <= r_Bit_Index + 1;
                            r_Clk_Count <= 0;
                        else
                            r_Clk_Count <= r_Clk_Count + 1;
                        end if;
                    else
                        r_SM <= s_RX_Stop_Bit;
                        r_Clk_Count <= 0;
                    end if;
                    
                when s_RX_Stop_Bit =>
                    if r_Clk_Count = g_CLKS_PER_BIT-1 then
                        if r_RX_Data = '1' then
                            r_SM <= s_Cleanup
                            r_Clk_Count <= 0;
                        else
                            r_SM <= s_Idle;
                        end if;
                    else
                        r_Clk_Count <= r_Clk_Count + 1;
                    end if;
                    
                when s_Cleanup =>
                    r_RX_DV <= '1';
                    r_RX_Byte <= X"00";
                    r_SM <= s_Idle;
                
                end case;

        end if;
    end process p_UART_RX;

    o_rx_dv    <= r_RX_DV;
    o_rx_byte  <= r_RX_Byte;

end rtl;
