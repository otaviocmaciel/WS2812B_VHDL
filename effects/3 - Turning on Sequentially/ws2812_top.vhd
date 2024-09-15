library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- WS2812 Controller - Top Level
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
    signal start    : std_logic := '1';
    signal done     : std_logic;
    signal Data     : std_logic_vector(0 to ((24*NUM_LEDS)-1)) := (others => '0');
    signal counter  : integer := 0;
    signal led_pos  : integer range 0 to (NUM_LEDS-1) := 0;  -- Posição do LED que estará aceso
    
    -- Definições de cor (pode ser alterado conforme desejado)
    constant LED_ON  : std_logic_vector(23 downto 0) := X"FFFFFF"; -- Cor vermelha (exemplo)
    constant LED_OFF : std_logic_vector(23 downto 0) := "000000000000000000000000"; -- LED apagado

begin

-- Processo para acender LEDs sequencialmente sem apagar os anteriores
    process(CLK, done)
    begin
        if rising_edge(CLK) then
            if done = '1' then
                -- Após a transmissão, atualiza a posição do LED e mantém os anteriores acesos
                if counter = 1000000 then
                    -- Acende o LED atual na posição `led_pos`
                    for i in 0 to (NUM_LEDS-1) loop
                        if i <= led_pos then
                            Data((i * 24) to (i * 24 + 23)) <= LED_ON; -- Acende o LED atual e os anteriores
                        else
                            Data((i * 24) to (i * 24 + 23)) <= LED_OFF; -- Mantém os próximos apagados
                        end if;
                    end loop;

                    -- Avança para o próximo LED
                    if led_pos = (NUM_LEDS-1) then
                        led_pos <= 0;
                    else
                        led_pos <= led_pos + 1;
                    end if;

                    -- Reinicia o contador
                    counter <= 0;
                    start <= '1';  -- Inicia a próxima transmissão
                else
                    counter <= counter + 1;
                    start <= '0';  -- Mantém a transmissão atual
                end if;
            end if;
        end if;
    end process;

-- Sinais de teste (opcional)
LED1 <= CLK;
LED2 <= done;

-- Instância do gerador de bits WS2812
uut1 : bit_gen 
    generic map(NUM_LEDS => NUM_LEDS)
    port map(
        clk => CLK, 
        reset_n => reset_n, 
        data_in => Data, 
        start => start, 
        led_out => WS2812, 
        done => done
    );
end hardware;
