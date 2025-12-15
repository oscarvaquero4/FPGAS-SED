----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.12.2025 15:44:45
-- Design Name: 
-- Module Name: EDGE - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity edge_detector is
    port (
        CLK       : in  std_logic;
        SIGNAL_IN : in  std_logic;
        PULSE_OUT : out std_logic
    );
end edge_detector;

architecture rtl of edge_detector is
    signal signal_d : std_logic := '0';
begin
    process (CLK)
    begin
        if rising_edge(CLK) then
            signal_d <= SIGNAL_IN;
        end if;
    end process;

    PULSE_OUT <= SIGNAL_IN and (not signal_d);
end rtl;