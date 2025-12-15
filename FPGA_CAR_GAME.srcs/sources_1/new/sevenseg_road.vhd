----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.12.2025 15:50:55
-- Design Name: 
-- Module Name: sevenseg_road - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity sevenseg_road_driver is
    port (
        CLK       : in  std_logic;
        RESET_N   : in  std_logic;
        ROAD_LEFT : in  unsigned(2 downto 0);  -- 0..7
        ROAD_RIGHT: in  unsigned(2 downto 0);  -- 0..7
        AN        : out std_logic_vector(7 downto 0); -- ánodos (activos en '0')
        SEG       : out std_logic_vector(6 downto 0)  -- segmentos a-g (activos en '0')
    );
end sevenseg_road_driver;

architecture rtl of sevenseg_road_driver is

    signal refresh_cnt : unsigned(15 downto 0) := (others => '0');
    signal digit_idx   : unsigned(2 downto 0)  := (others => '0'); -- 0..7

    -- Segmentos activos a nivel bajo: 1 = apagado, 0 = encendido
    constant SEG_OFF          : std_logic_vector(6 downto 0) := (others => '1');
    -- Solo palos izquierdos: segmentos f y e encendidos
    -- SEG(6 downto 0) = a b c d e f g
    constant SEG_LEFT_BORDER  : std_logic_vector(6 downto 0) := "1001111"; -- f,e = 0
    -- Solo palos derechos: segmentos b y c encendidos
    constant SEG_RIGHT_BORDER : std_logic_vector(6 downto 0) := "1111001"; -- b,c = 0

begin

    -- Contador de refresco
    process (CLK, RESET_N)
    begin
        if RESET_N = '0' then
            refresh_cnt <= (others => '0');
        elsif rising_edge(CLK) then
            refresh_cnt <= refresh_cnt + 1;
        end if;
    end process;

    -- Usamos los bits más altos como índice de dígito
    digit_idx <= refresh_cnt(15 downto 13);  -- recorre 0..7 bastante rápido

    -- Lógica de selección de dígito y segmentos
    process (digit_idx, ROAD_LEFT, ROAD_RIGHT)
        variable idx_i   : integer;
        variable left_i  : integer;
        variable right_i : integer;
        variable an_i    : std_logic_vector(7 downto 0);
        variable seg_i   : std_logic_vector(6 downto 0);
    begin
        an_i  := (others => '1');  -- todos apagados
        seg_i := SEG_OFF;

        idx_i   := to_integer(digit_idx);
        left_i  := to_integer(ROAD_LEFT);
        right_i := to_integer(ROAD_RIGHT);

        if idx_i >= 0 and idx_i <= 7 then
            an_i(idx_i) := '0'; -- ese dígito activo (anodo activo en '0')

            if idx_i = left_i then
                seg_i := SEG_LEFT_BORDER;
            elsif idx_i = right_i then
                seg_i := SEG_RIGHT_BORDER;
            else
                seg_i := SEG_OFF;
            end if;
        end if;

        AN  <= an_i;
        SEG <= seg_i;
    end process;

end rtl;