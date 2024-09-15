library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

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

    -- LFSR (Linear Feedback Shift Register) para gerar números pseudo-aleatórios
    signal lfsr : std_logic_vector(15 downto 0) := "1101011101010101";  -- Semente inicial para o LFSR

    -- Cor genérica para acender os LEDs
    signal color_generic : std_logic_vector(23 downto 0) := "111111110000000011111111"; -- Cor aleatória inicial (rosa)

    -- Processo para gerar o próximo valor do LFSR (pseudo-random)
    procedure lfsr_next(signal lfsr_in : inout std_logic_vector) is
    begin
        -- Realiza o deslocamento e aplica o XOR para manter a pseudo-aleatoriedade
        lfsr_in <= lfsr_in(14 downto 0) & (lfsr_in(15) xor lfsr_in(13) xor lfsr_in(12) xor lfsr_in(10));
    end procedure;

begin

-- Processo principal para acender LEDs de forma aleatória
process(CLK, done)
    variable led_random : std_logic;  -- Variável para decidir se o LED será aceso ou apagado
begin
    if rising_edge(CLK) then
        if done = '1' then
            if counter = 10000000 then
                -- Apaga todos os LEDs
                Data <= (others => '0');
                
                -- Atualiza o LFSR para gerar um novo número pseudo-aleatório
                lfsr_next(lfsr);
                
                -- Acende os LEDs de acordo com o valor pseudo-aleatório gerado
                for i in 0 to (NUM_LEDS-1) loop
                    -- Usando o LFSR para decidir se o LED será aceso ou não
                    led_random := lfsr(i mod 16);
                    
                    if led_random = '1' then
                        -- Acende o LED com a cor genérica
                        Data((i * 24) to (i * 24 + 23)) <= color_generic;  -- LED aceso com cor genérica
                    else
                        -- LED apagado
                        Data((i * 24) to (i * 24 + 23)) <= "000000000000000000000000"; -- LEDs apagados
                    end if;
                end loop;

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
