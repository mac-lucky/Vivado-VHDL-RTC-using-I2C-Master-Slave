library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity RTC is
    Generic(
        IN_CLK : integer := 50000000; --50MHz
        BUS_CLK: integer := 400000 --400kHz
        );
    Port(
        CLK : in std_logic;     --zegar 50MHz
        R_n : in std_logic;     --reset aktywowany stanem niskim
        ENA : in std_logic;     --aktywowanie wys³ania/odebrania danych
        ADDRESS : in std_logic_vector(7 downto 0);      --adres slave; bit 0 to bit R/W
        DATA_WR : in std_logic_vector(7 downto 0);      --dane do zapisu
        DATA_RD : out std_logic_vector(7 downto 0);     --dane odczytane
        ACK_ERROR : buffer std_logic;      --b³¹d przy odczytywaniu bitów ack
        BUSY : out std_logic;           --sygnalizacja zajêcia
        SDA : inout std_logic;
        SCL : inout std_logic
        );
end RTC;

architecture RTC_arch of RTC is

constant div : integer := (in_clk/bus_clk); --ile taktów zegara uProcesora w jednym takcie zegara lini SCL (chyba)?????????????????????

type STATES is (Idle,Start,Addressing,S_Ack1,S_Ack2,M_Ack,Read,Write,Stop);
signal STATE : STATES := Idle;

signal data_clk, data_clk_prev : std_logic; --zegar lini SDA i jego stan poprzedni
signal scl_clk : std_logic; --wewnetrzny zegar scl
signal scl_ena : std_logic := '0';  --przekazywanie wewnetrznego scl na wyjscie
signal sda_int : std_logic := '1';  --wewnetrzna linia sda
signal sda_ena_n : std_logic;   --przekazywanie wew. sda na wyjscie
signal address_s : std_logic_vector(7 downto 0); --sygna³ przechowujacy podany adres i bit R/W
signal data_rd_s, data_wr_s: std_logic_vector(7 downto 0); --sygnal przechowuj¹cy dane do odczytu/zapisu
signal index : integer range 0 to 7 := 7; --sygnal do zliczania bitow
signal sync : std_logic := '0'; --sygnal informujacy o opoznianiu zegara przez slave tzw. streching




begin
Gen_SCL: process(CLK,R_n)       --proces odpowiedzialny za generowanie sygna³u zegarowego na lini SCL i SDA w wew. sygna³ach scl_clk i data_clk
    variable count : integer range 0 to div;    --liczenie taktow zegara
Begin   --proces podzielony na 4 cwiartki tak aby osiagnac opóznienie wew. zegara dla danych wzgledem zegara wew. scl
    if(R_n = '0') then  --oraz by umo¿liwic wykrycie rozciagania zegara przez slave (chyba) ???????????????
        sync <= '0';
        count := 0;
    elsif(CLK'event and CLK = '1') then
        data_clk_prev <= data_clk;
        
        if(count = div-1) then
            count := 0;
        elsif(sync = '0') then
            count := count + 1;
        end if;
    case count is
        when 0 to div/4 - 1 =>
            scl_clk <= '0';
            data_clk <= '0';
        when div/4 to div/2-1 =>
            scl_clk <= '0';
            data_clk <= '1';
        when div/2 to div*3/4 - 1 =>
            scl_clk <= '1';
            if(scl = '0') then --jesli slave podaje 0 na linie scl to wymaga spowolnienia zegara
                sync <= '1';
            else
                sync <= '0';
            end if;
            data_clk <= '1';
        when others =>
            scl_clk <= '1';
            data_clk <= '0';
    end case;
    end if;
end process Gen_SCL;

I2Cmaster: process(CLK,R_n)
begin
    if(R_n = '0') then              --reset aktywny
        state <= Idle;              --powrót do stanu domyslnego
        busy <= '1';                --sygnalizowanie zajêcia
        scl_ena <= '0';             --linia scl w stanie Z
        sda_int <= '1';             --linia sda w stanie Z
        ack_error <= '0';           --wyczyszczenie bledu ack
        index <= 7;                 --wyzerowanie licznika bitow
        data_rd <= (others => '0');  --wyzerowanie wyjscia z odzczytanymi danymi         
    elsif(CLK'event and CLK = '1') then
        if(data_clk = '1' and data_clk_prev = '0') then --dzialania na zboczu narastajacym zegara lini danych
            case STATE is
                when Idle =>
                    if(ena = '1') then --rozpoczecie transmisji
                        busy <= '1';
                        address_s <= ADDRESS;
                        data_wr_s <= data_wr;
                        STATE <= Start;
                    else
                        busy <= '0';
                        STATE <= Idle;
                    end if;
                when Start =>
                    busy <= '1';
                    sda_int <= address_s(index);    --wyslanie pierwszego bitu adresu
                    STATE <= Addressing;
                when Addressing =>
                    if(index = 0) then  --warunek spelniony jesli wyslano wszystkie 8 bitow
                        sda_int <= '1'; --linia w stanie wysokiej impedancji - slave moze wyslac bit ack
                        index <= 7;
                        STATE <= S_Ack1;
                    else 
                        index <= index - 1;
                        sda_int <= address_s(index-1);  --wysylanie kolejnych bitow (dlaczego dwa razy -1 ????????)
                        STATE <= Addressing;
                    end if;
                when S_Ack1 =>
                    if(address_s(0) = '0') then     --zapis danych
                        sda_int <= data_wr_s(index);--wyslanie pierwszego bitu danych
                        STATE <= Write;
                    else
                        sda_int <= '1';             --linia sda w stanie Z do ocztytu danych
                        state <= Read;
                    end if;
                when Write =>
                    busy <= '1';
                    if(index = 0) then
                        sda_int <= '1';
                        index <= 7;
                        STATE <= S_Ack2;
                    else
                        index <= index - 1;
                        sda_int <= data_wr(index - 1);
                        STATE <= Write;
                    end if;
                when Read =>
                    busy <= '1';
                    if(index = 0) then
                        if(ena = '1' and address_s = ADDRESS) then --jesli ena = 1 i adres sie nie zmieni³ odzczytujemy kolejny bajt;
                            sda_int <= '0';
                        else
                            sda_int <= '1';
                        end if;
                        index <= 7;
                        DATA_RD <= data_rd_s;
                        STATE <= M_Ack;
                    else
                        index <= index - 1;
                        STATE <= Read;
                    end if;
                when S_Ack2 =>
                    if(ena = '1') then      --jesli ena = 1 to kontynuujemy zapisywanie danych
                        busy <= '0';
                        address_s <= ADDRESS;
                        data_wr_s <= DATA_WR;
                        if (address_s = ADDRESS) then
                            sda_int <= '1';
                            STATE <= Write;
                        else
                            STATE <= Start;
                        end if;
                    else
                        STATE <= Stop;
                    end if;
                when M_Ack =>           --jesli ena = 1 to kontynuujemy odczytywanie danych
                    if(ena = '1') then 
                        busy <= '1';
                        address_s <= ADDRESS;
                        data_wr_s <= DATA_WR;
                        if(address_s = ADDRESS) then
                            sda_int <= '1';
                            STATE <= Read;
                        else
                            STATE <= Start;
                        end if;
                    else
                        STATE <= Start;
                    end if;
                when Stop =>
                    busy <= '0';
                    STATE <= Idle;
            end case;
        elsif(data_clk = '0' and data_clk_prev = '1') then      --dzialania na zboczu opadajacym zegara lini danych
            case STATE is
                when Start =>
                    if(scl_ena = '0') then      --rozpoczecie transmisji
                        scl_ena <= '1';
                        ACK_ERROR <= '0';
                    end if;
                when S_Ack1 =>
                    if(SDA /= '0' OR ACK_ERROR = '1') then --slave nie wyslal bitu ack albo pojawil sie blad ack
                        ACK_ERROR <= '1';
                    end if;
                when Read =>
                    data_rd_s(index) <= SDA;        -- zapisywanie kolejnych bitow podanych na SDA
                when S_Ack2 =>
                    if(SDA /= '0' OR ACK_ERROR = '1') then
                        ACK_ERROR <= '1';
                    end if;
                when Stop =>
                    scl_ena <= '0';
                when others =>
                    NULL;
            end case;
        end if;
    end if;                                                    
end process I2Cmaster;

with STATE select
    sda_ena_n <= data_clk_prev when Start,          --generowanie warunku startu - linia SDA opada przed lini¹ SCL
                 NOT data_clk_prev when Stop,       --generowanie warunku stopu - linia SDA wzrasta przed lini¹ SCL
                 sda_int when others;               --ustawianie na stan wewn¹trznego sygna³u lini SDA 

SCL <= '0' when (scl_ena = '1' and scl_clk = '0') else 'Z';
SDA <= '0' when sda_ena_n = '0' else 'Z';

end RTC_arch;
