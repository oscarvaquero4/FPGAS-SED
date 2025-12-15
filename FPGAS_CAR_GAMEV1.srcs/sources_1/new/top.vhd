----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.12.2025 15:42:05
-- Design Name: 
-- Module Name: top - Behavioral
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

entity top_car_game is
    port (
        CLK       : in  std_logic;
        RESET_N   : in  std_logic;  -- reset global activo a '0'
        BTN_LEFT  : in  std_logic;
        BTN_RIGHT : in  std_logic;
        BTN_START : in  std_logic;
        LEDS      : out std_logic_vector(9 downto 0);
        SEG       : out std_logic_vector(6 downto 0);
        AN        : out std_logic_vector(7 downto 0);
        DP        : out std_logic                  -- punto decimal (todos apagados)
    );
end top_car_game;

architecture behavioral of top_car_game is

    --------------------------------------------------------------------
    -- Señales de botones sincronizados y pulsos
    --------------------------------------------------------------------
    signal left_sync,  right_sync,  start_sync  : std_logic;
    signal left_pulse, right_pulse, start_pulse: std_logic;

    --------------------------------------------------------------------
    -- Tick de juego y FSM de juego
    --------------------------------------------------------------------
    signal tick_game          : std_logic;
    signal s_idle, s_play     : std_logic;
    signal s_crash, s_gameover: std_logic;

    --------------------------------------------------------------------
    -- Coche y carretera
    --------------------------------------------------------------------
    constant MIN_POS : integer := 0;  -- usamos LEDs/dígitos 1..6 (0 y 7 como arcenes)
    constant MAX_POS : integer := 9;

    signal car_pos     : integer range MIN_POS to MAX_POS := 3;
    signal road_center : integer range 1 to 6 := 3;
    signal road_dir    : std_logic := '0'; -- '0' hacia derecha, '1' hacia izquierda
    signal crash       : std_logic := '0';

    -- Para el driver de 7 segmentos
    signal road_left_u, road_right_u : unsigned(2 downto 0);
    
    -- Dificultad
    signal score      : unsigned(15 downto 0) := (others => '0');  -- tiempo/puntuación
    signal difficulty : integer range 0 to 2 := 0;
    
    -- RANDOM
    signal rand : std_logic_vector(7 downto 0);
    -- Señal para controlar la velocidad del reloj
    signal current_divisor : unsigned(31 downto 0);
    --------------------------------------------------------------------
    -- Declaración de componentes
    --------------------------------------------------------------------
    component synchronizer
        port (
            CLK      : in  std_logic;
            ASYNC_IN : in  std_logic;
            SYNC_OUT : out std_logic
        );
    end component;

    component edge_detector
        port (
            CLK       : in  std_logic;
            SIGNAL_IN : in  std_logic;
            PULSE_OUT : out std_logic
        );
    end component;

   component clock_divider
        port (
            CLK        : in  std_logic;
            RESET_N    : in  std_logic;
            DIVISOR_IN : in  unsigned(31 downto 0); 
            TICK_OUT   : out std_logic
        );
    end component;

    component car_game_fsm
        port (
            CLK         : in  std_logic;
            RESET_N     : in  std_logic;
            START_PULSE : in  std_logic;
            CRASH       : in  std_logic;
            TICK_GAME   : in  std_logic;
            STATE_IDLE      : out std_logic;
            STATE_PLAY      : out std_logic;
            STATE_CRASH     : out std_logic;
            STATE_GAME_OVER : out std_logic
        );
    end component;

    component sevenseg_road_driver
        port (
            CLK       : in  std_logic;
            RESET_N   : in  std_logic;
            ROAD_LEFT : in  unsigned(2 downto 0);
            ROAD_RIGHT: in  unsigned(2 downto 0);
            AN        : out std_logic_vector(7 downto 0);
            SEG       : out std_logic_vector(6 downto 0)
        );
    end component;
    
    component rndm is
        Port ( 
            CLK     : in STD_LOGIC;
            RESET_N : in STD_LOGIC;
            RANDOM  : out STD_LOGIC_VECTOR(7 downto 0) -- O el tamaño que sea
        );
    end component;

begin

    
    --------------------------------------------------------------------
    -- Sincronizadores + detectores de flanco para los botones
    --------------------------------------------------------------------
    u_sync_left : synchronizer
        port map (
            CLK      => CLK,
            ASYNC_IN => BTN_LEFT,
            SYNC_OUT => left_sync
        );

    u_edge_left : edge_detector
        port map (
            CLK       => CLK,
            SIGNAL_IN => left_sync,
            PULSE_OUT => left_pulse
        );

    u_sync_right : synchronizer
        port map (
            CLK      => CLK,
            ASYNC_IN => BTN_RIGHT,
            SYNC_OUT => right_sync
        );

    u_edge_right : edge_detector
        port map (
            CLK       => CLK,
            SIGNAL_IN => right_sync,
            PULSE_OUT => right_pulse
        );

    u_sync_start : synchronizer
        port map (
            CLK      => CLK,
            ASYNC_IN => BTN_START,
            SYNC_OUT => start_sync
        );

    u_edge_start : edge_detector
        port map (
            CLK       => CLK,
            SIGNAL_IN => start_sync,
            PULSE_OUT => start_pulse
        );

    --------------------------------------------------------------------
    -- Divisor de reloj: genera tick de juego
    --------------------------------------------------------------------
   u_clkdiv : clock_divider
       
        port map (
            CLK        => CLK,
            RESET_N    => RESET_N,
            DIVISOR_IN => current_divisor, -- Conectamos la señal de velocidad
            TICK_OUT   => tick_game
        );
        
    u_randd : rndm
    port map (
        CLK     => CLK,
        RESET_N => RESET_N,
        RANDOM  => rand
    );

    --------------------------------------------------------------------
    -- FSM del juego
    --------------------------------------------------------------------
    u_game_fsm : car_game_fsm
        port map (
            CLK         => CLK,
            RESET_N     => RESET_N,
            START_PULSE => start_pulse,
            CRASH       => crash,
            TICK_GAME   => tick_game,
            STATE_IDLE      => s_idle,
            STATE_PLAY      => s_play,
            STATE_CRASH     => s_crash,
            STATE_GAME_OVER => s_gameover
        );

    --------------------------------------------------------------------
    -- Movimiento del coche (con botones) y de la carretera (automático)
    --------------------------------------------------------------------
    process (CLK, RESET_N)
    begin
        if RESET_N = '0' then
            car_pos     <= 4;
            road_center <= 3;
            road_dir    <= '0';
        elsif rising_edge(CLK) then

            -- En IDLE reseteamos posiciones
            if s_idle = '1' then
                car_pos     <= 4;
                road_center <= 3;
                road_dir    <= '0';
                score       <= (others => '0');
                difficulty  <= 0;  -- siempre empezamos en fácil

            -- En PLAY se mueve coche + carretera
            elsif s_play = '1' then

                -- Coche con botones
                if left_pulse = '1' and car_pos > 0 then
                    car_pos <= car_pos - 1;
                elsif right_pulse = '1' and car_pos < 9 then
                    car_pos <= car_pos + 1;
                end if;

                -- Carretera se mueve sola con tick_game
                if tick_game = '1' then
                score <= score + 1; -- se actualiza el tiempo de juego
                     if  score < 10 then
                         difficulty <= 0;       -- primeros segundos: fácil
                         elsif score < 20 then
                         difficulty <= 1;       -- medio
                     else
                         difficulty <= 2;       -- chungo
                         end if;
                    
                    case difficulty is

            ----------------------------------------------------------------
            -- DIFICULTAD 0: como ahora (lento y determinista)
            ----------------------------------------------------------------
            when 0 =>
                -- rebote en bordes
                current_divisor <= to_unsigned(100_000_000, 32);
                if road_center = 6 then
                    road_dir <= '1';  -- izquierda
                elsif road_center = 1 then
                    road_dir <= '0';  -- derecha
                end if;

                -- mover centro
                if road_dir = '0' and road_center < 6 then
                    road_center <= road_center + 1;
                elsif road_dir = '1' and road_center > 1 then
                    road_center <= road_center - 1;
                end if;

            ----------------------------------------------------------------
            -- DIFICULTAD 1: MÁS RÁPIDO
            -- simplemente hacemos dos pasos por cada tick
            ----------------------------------------------------------------
            when 1 =>
                -- primer paso (igual que dificultad 0)
                current_divisor <= to_unsigned(80_000_000, 32);
                if road_center = 6 then
                    road_dir <= '1';
                elsif road_center = 1 then
                    road_dir <= '0';
                end if;

                if road_dir = '0' and road_center < 6 then
                    road_center <= road_center + 1;
                elsif road_dir = '1' and road_center > 1 then
                    road_center <= road_center - 1;
                end if;

                -- segundo paso extra si todavía no está en el borde
                if road_dir = '0' and road_center < 6 then
                    road_center <= road_center + 1;
                elsif road_dir = '1' and road_center > 1 then
                    road_center <= road_center - 1;
                end if;

            ----------------------------------------------------------------
            -- DIFICULTAD 2: ALEATORIO
            ----------------------------------------------------------------
            when others =>
                -- elegimos dirección aleatoria con rand(0), pero sin salirnos
                current_divisor <= to_unsigned(60_000_000, 32);
                if rand(0) = '0' then
                    -- intentar ir a la derecha
                    if road_center < 6 then
                        road_center <= road_center + 1;
                    end if;
                else
                    -- intentar ir a la izquierda
                    if road_center > 1 then
                        road_center <= road_center - 1;
                    end if;
                end if;

                 end case;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Condición de choque: el coche debe ir SIEMPRE en el centro
    --------------------------------------------------------------------
    crash <= '1' when (s_play = '1' and (road_center + 2 < car_pos or road_center -1 > car_pos)) else '0';

    --------------------------------------------------------------------
    -- LEDs: muestran SOLO la posición del coche
    --------------------------------------------------------------------
    gen_leds : for i in 0 to 9 generate
        LEDS(i) <= '1' when ( (s_play = '1' or s_idle = '1') and car_pos = i )
                   else '0';
    end generate;

    --------------------------------------------------------------------
    -- Conversión de centro de carretera a bordes para el driver de 7seg
    --------------------------------------------------------------------
    road_left_u  <= to_unsigned(road_center - 1, 3);
    road_right_u <= to_unsigned(road_center + 1, 3);

    --------------------------------------------------------------------
    -- Driver de 7 segmentos: pinta los bordes de la carretera
    --------------------------------------------------------------------
    u_7seg : sevenseg_road_driver
        port map (
            CLK        => CLK,
            RESET_N    => RESET_N,
            ROAD_LEFT  => road_left_u,
            ROAD_RIGHT => road_right_u,
            AN         => AN,
            SEG        => SEG
        );

    -- Apagamos siempre los puntos decimales
    DP <= '1';  -- activo a '0' normalmente en Nexys A7

end behavioral;