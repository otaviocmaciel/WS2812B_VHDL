library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--
--  Develop by José Otávio Cavalcanti Maciel
--  WS2812 Controller
--
--  The Tang Nano 20K development board
--  has WS2812 LED embedded in the PCB.
--
--  The WS2812 is a RGB LED and use Single-Wire
--  to change the intensity of colors.
--
--  The Package is composed by MSB format
--  24 bits:
--      * 8 bits for green
--      * 8 bits for red
--      * 8 bits for blue
--
--  1.25us per bit
--  Bit 1 -> TH: 0.75us     TL: 0.6us
--  Bit 0 -> TH: 0.35us     TL: 0.8us
--  Reset -> 50us


entity ws2812_top is
generic(
        NUM_LEDS : integer := 300  -- Número de LEDs WS2812B a serem controlados
    );
port(
    CLK         : in std_logic;
    WS2812      : out std_logic;
    LED1, LED2  : out std_logic
);
end ws2812_top;

architecture hardware of ws2812_top is

component bit_gen is
    generic(
        NUM_LEDS : integer := NUM_LEDS  -- Número de LEDs WS2812B a serem controlados
    );
    port (
        clk        : in std_logic;            -- Clock de 100 MHz
        reset_n    : in std_logic;            -- Reset ativo em nível baixo
        data_in    : in std_logic_vector(0 to ((24*NUM_LEDS)-1));  -- Dados RGB (8 bits para cada cor)
        start      : in std_logic;            -- Sinal para iniciar a transmissão
        led_out    : out std_logic;           -- Sinal de controle para o LED
        done       : out std_logic            -- Indica que a transmissão foi concluída
    );
end component;

signal reset_n  : std_logic := '1';
--signal RGB1      : std_logic_vector(0 to 23) := "111111110000000000000000";
--signal RGB2      : std_logic_vector(0 to 23) := "000000001111111100000000";
signal start	: std_logic := '1';
signal done	    : std_logic;
signal Data     : std_logic_vector(0 to ((24*NUM_LEDS)-1)) := (others => '1');

type state_type is (G, R, B);
signal state : state_type := G;
signal counter : integer := 0;
begin

process(CLK, done)
begin
if rising_edge(CLK) then
    if counter < 1000000 then
        counter <= counter + 1;
        if(done = '0') then
            start <= '0';
        end if;
    else
    counter <= 0;
    --RGB1 <= std_logic_vector(unsigned(RGB1) + 1);
    start <= '1';
    end if;
end if;
end process;

--Data <= RGB1 & RGB2;

LED1 <= CLK;
LED2 <= done;

uut1 : bit_gen port map(CLK => CLK, reset_n => reset_n, data_in => Data, start => start, led_out => WS2812, done => done);
end hardware;