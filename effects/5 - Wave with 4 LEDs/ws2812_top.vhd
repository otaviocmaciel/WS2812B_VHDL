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
    
    -- Posição para controle da "onda"
    signal led_pos  : integer range 3 to (NUM_LEDS-1) := 3;  -- Começa com o 4º LED
    signal intensity_max : std_logic_vector(7 downto 0) := "11111111"; -- Brilho máximo (255)
    
    -- Cores para a onda (pode ser alterado para outras cores se necessário)
    signal LED_1_INTENSITY, LED_2_INTENSITY, LED_3_INTENSITY, LED_4_INTENSITY : std_logic_vector(23 downto 0);

begin

-- Definir a intensidade dos LEDs baseando-se na posição da "onda"
process(led_pos, intensity_max)
begin
    -- LED mais forte (brilho máximo)
    LED_1_INTENSITY <= intensity_max & "00000000" & "00000000";  -- LED verde com brilho máximo (por exemplo)
    -- Antecessores com 1/2, 1/4 e 1/8 do brilho
    LED_2_INTENSITY <= std_logic_vector(unsigned(intensity_max) / 2) & "00000000" & "00000000";  -- 1/2 brilho
    LED_3_INTENSITY <= std_logic_vector(unsigned(intensity_max) / 4) & "00000000" & "00000000";  -- 1/4 brilho
    LED_4_INTENSITY <= std_logic_vector(unsigned(intensity_max) / 16) & "00000000" & "00000000";  -- 1/8 brilho
end process;

-- Processo para percorrer os LEDs e criar o efeito de onda
process(CLK, done, LED_1_INTENSITY, LED_2_INTENSITY, LED_3_INTENSITY, LED_4_INTENSITY)
begin
    if rising_edge(CLK) then
        if done = '1' then
            if counter = 10000000 then
                -- Apaga todos os LEDs
                Data <= (others => '0');

                -- Acende os 4 LEDs da "onda" com brilhos decrescentes
                for i in 0 to (NUM_LEDS-1) loop
                    if i = led_pos then
                        Data((i * 24) to (i * 24 + 23)) <= LED_1_INTENSITY;  -- LED de maior intensidade
                    elsif i = led_pos - 1 then
                        Data((i * 24) to (i * 24 + 23)) <= LED_2_INTENSITY;  -- LED com 1/2 do brilho
                    elsif i = led_pos - 2 then
                        Data((i * 24) to (i * 24 + 23)) <= LED_3_INTENSITY;  -- LED com 1/4 do brilho
                    elsif i = led_pos - 3 then
                        Data((i * 24) to (i * 24 + 23)) <= LED_4_INTENSITY;  -- LED com 1/8 do brilho
                    else
                        Data((i * 24) to (i * 24 + 23)) <= "000000000000000000000000"; -- LEDs apagados
                    end if;
                end loop;

                -- Avança para o próximo LED na "onda"
                if led_pos = (NUM_LEDS-1) then
                    led_pos <= 3;  -- Reinicia a "onda"
                else
                    led_pos <= led_pos + 1;
                end if;

                -- Reinicia o contador
                counter <= 0;
                start <= '1';
            else
                counter <= counter + 1;
                start <= '0';
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
