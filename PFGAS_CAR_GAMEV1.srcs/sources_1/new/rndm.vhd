----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.12.2025 10:13:48
-- Design Name: 
-- Module Name: RANDOM - Behavioral
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

entity random is
    port(
        CLK     : in  std_logic;
        RESET_N : in  std_logic;
        RANDOM  : out std_logic_vector(7 downto 0)
    );
end random;

architecture rtl of random is
    signal r : std_logic_vector(7 downto 0) := "10101101";
begin
    process(CLK, RESET_N)
        variable feedback : std_logic;
    begin
        if RESET_N = '0' then
            r <= "10101101";  -- semilla
        elsif rising_edge(CLK) then
            feedback := r(7) xor r(5) xor r(4) xor r(3);
            r <= feedback & r(7 downto 1);
        end if;
    end process;

    RANDOM <= r;
end rtl;