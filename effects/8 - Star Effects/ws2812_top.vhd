library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ws2812_top is
    generic(
        NUM_LEDS      : integer := 300;  -- Número de LEDs WS2812B a serem controlados
        MAX_STARS     : integer := 50    -- Número máximo de estrelas (LEDs piscando)
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

    -- Controle de brilho para cada estrela
    type brightness_array is array (0 to NUM_LEDS-1) of integer range 0 to 255;
    signal brightness_levels : brightness_array := (others => 0);

    -- Array de estado para controlar se uma estrela está crescendo ou diminuindo de brilho
    type state_array is array (0 to NUM_LEDS-1) of std_logic;
    signal star_growing : state_array := (others => '0');

    -- Randomização para escolher as posições das estrelas
    signal random_pos : integer := 0;

    -- Constantes de cores
    constant STAR_COLOR : std_logic_vector(23 downto 0) := "111111111111111111111111";  -- Cor amarela (RGB: amarelo)
    constant LED_OFF    : std_logic_vector(23 downto 0) := "000000000000000000000000";  -- LED apagado

begin

    -- Processo para gerar o efeito de estrelas piscando
    process(CLK, done)
    begin
        if rising_edge(CLK) then
            if done = '1' then
                if counter = 10000000 then
                    -- Reinicia o contador
                    counter <= 0;

                    -- Atualiza o brilho de cada LED
                    for i in 0 to (NUM_LEDS-1) loop
                        if brightness_levels(i) > 0 or star_growing(i) = '1' then
                            -- Se o LED está aceso ou crescendo, ajusta o brilho
                            if star_growing(i) = '1' then
                                brightness_levels(i) <= brightness_levels(i) + 5;
                                if brightness_levels(i) >= 255 then
                                    star_growing(i) <= '0';  -- Começa a diminuir o brilho
                                end if;
                            else
                                brightness_levels(i) <= brightness_levels(i) - 5;
                                if brightness_levels(i) <= 0 then
                                    brightness_levels(i) <= 0;  -- Apaga completamente
                                end if;
                            end if;

                            -- Ajusta a cor com base no brilho
                            Data((i * 24) to (i * 24 + 23)) <= STAR_COLOR(23 downto 16) & 
                                                               std_logic_vector(to_unsigned(brightness_levels(i), 8)) &
                                                               STAR_COLOR(7 downto 0);
                        else
                            -- Mantém o LED apagado
                            Data((i * 24) to (i * 24 + 23)) <= LED_OFF;
                        end if;
                    end loop;

                    -- Randomiza a posição para acender uma nova estrela
                    random_pos <= (random_pos + 157) mod NUM_LEDS;  -- Número pseudo-aleatório
                    if brightness_levels(random_pos) = 0 then
                        star_growing(random_pos) <= '1';  -- Inicia o crescimento de uma nova estrela
                    end if;

                    -- Inicia a transmissão
                    start <= '1';
                else
                    counter <= counter + 1;
                    start <= '0';  -- Desativa o start até que done seja '1' novamente
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
