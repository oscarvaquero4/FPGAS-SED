----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.12.2025 15:46:44
-- Design Name: 
-- Module Name: CLK_DIVIDER - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Clock divider con velocidad variable
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock_divider is
    port (
        CLK        : in  std_logic;
        RESET_N    : in  std_logic;
        -- AQUI EL CAMBIO: Ya no es generic, es una entrada
        DIVISOR_IN : in  unsigned(31 downto 0); 
        TICK_OUT   : out std_logic
    );
end clock_divider;

architecture rtl of clock_divider is
    signal counter : unsigned(31 downto 0) := (others => '0');
    signal tick_i  : std_logic := '0';
begin
    process (CLK, RESET_N)
    begin
        if RESET_N = '0' then
            counter <= (others => '0');
            tick_i  <= '0';
        elsif rising_edge(CLK) then
            -- CAMBIO DE SEGURIDAD: Usar >= en lugar de =
            -- Si DIVISOR_IN cambia bruscamente a un valor bajo, esto evita errores.
            if counter >= (DIVISOR_IN - 1) then
                counter <= (others => '0');
                tick_i  <= '1';
            else
                counter <= counter + 1;
                tick_i  <= '0';
            end if;
        end if;
    end process;

    TICK_OUT <= tick_i;
end rtl;