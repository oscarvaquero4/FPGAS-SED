----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.12.2025 15:42:45
-- Design Name: 
-- Module Name: SINCRONIZER - Behavioral
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

entity synchronizer is
    port (
        CLK      : in  std_logic;
        ASYNC_IN : in  std_logic;
        SYNC_OUT : out std_logic
    );
end synchronizer;

architecture rtl of synchronizer is
    signal ff1, ff2 : std_logic := '0';
begin
    process (CLK)
    begin
        if rising_edge(CLK) then
            ff1 <= ASYNC_IN;
            ff2 <= ff1;
        end if;
    end process;

    SYNC_OUT <= ff2;
end rtl;

