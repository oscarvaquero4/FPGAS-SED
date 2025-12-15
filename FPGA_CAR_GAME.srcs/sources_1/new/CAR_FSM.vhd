----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.12.2025 15:48:49
-- Design Name: 
-- Module Name: CAR_FSM - Behavioral
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

entity car_game_fsm is
    port (
        CLK         : in  std_logic;
        RESET_N     : in  std_logic;  -- activo a '0'
        START_PULSE : in  std_logic;  -- pulso de botón start
        CRASH       : in  std_logic;  -- 1 cuando hay choque
        TICK_GAME   : in  std_logic;  -- tick lento de juego
        STATE_IDLE      : out std_logic;
        STATE_PLAY      : out std_logic;
        STATE_CRASH     : out std_logic;
        STATE_GAME_OVER : out std_logic
    );
end car_game_fsm;

architecture behavioral of car_game_fsm is
    type STATES is (S_IDLE, S_PLAY, S_CRASH, S_GAME_OVER);
    signal current_state, next_state : STATES := S_IDLE;
begin

    -- Registro de estado
    process (CLK, RESET_N)
    begin
        if RESET_N = '0' then
            current_state <= S_IDLE;
        elsif rising_edge(CLK) then
            current_state <= next_state;
        end if;
    end process;

    -- Lógica de siguiente estado
    process (current_state, START_PULSE, CRASH, TICK_GAME)
    begin
        next_state <= current_state;

        case current_state is
            when S_IDLE =>
                if START_PULSE = '1' then
                    next_state <= S_PLAY;
                end if;

            when S_PLAY =>
                if CRASH = '1' then
                    next_state <= S_CRASH;
                end if;

            when S_CRASH =>
                -- después de un tick de juego pasamos a GAME_OVER
                if TICK_GAME = '1' then
                    next_state <= S_GAME_OVER;
                end if;

            when S_GAME_OVER =>
                if START_PULSE = '1' then
                    next_state <= S_IDLE;
                end if;

            when others =>
                next_state <= S_IDLE;
        end case;
    end process;

    -- Salidas tipo Moore
    STATE_IDLE      <= '1' when current_state = S_IDLE      else '0';
    STATE_PLAY      <= '1' when current_state = S_PLAY      else '0';
    STATE_CRASH     <= '1' when current_state = S_CRASH     else '0';
    STATE_GAME_OVER <= '1' when current_state = S_GAME_OVER else '0';

end behavioral;