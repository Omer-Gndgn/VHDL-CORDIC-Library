library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RotationMode is
    Generic (
        DATA_WIDTH : integer := 16;  
        ITERATIONS : integer := 16   
    );
    Port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        start    : in  std_logic;
        angle_in : in  signed(DATA_WIDTH-1 downto 0); 
        
        
        sin_out  : out signed(DATA_WIDTH-1 downto 0);
        cos_out  : out signed(DATA_WIDTH-1 downto 0);
        done     : out std_logic
    );
end RotationMode;

architecture Behavioral of RotationMode is

    -- SABİTLER
    -- Sınır Değerleri (Q3.13 Formatı)
    constant DEG_90  : signed(DATA_WIDTH-1 downto 0) := to_signed(12868, DATA_WIDTH);
    constant DEG_NEG_90 : signed(DATA_WIDTH-1 downto 0) := to_signed(-12868, DATA_WIDTH);
    
    -- 180 Derece (Düzeltme için) - Dikkat: Bu register genişliğinde olmalı
    constant DEG_180 : signed(DATA_WIDTH+1 downto 0) := to_signed(25736, DATA_WIDTH+2);
    
    -- LUT Tanımı: 16 elemanlı
    type angle_lut_type is array (0 to ITERATIONS-1) of signed(DATA_WIDTH-1 downto 0);
    constant ANGLE_LUT : angle_lut_type := (
        to_signed(6433, DATA_WIDTH), -- i=0  (45.00 deg)
        to_signed(3798, DATA_WIDTH), -- i=1  (26.56 deg)
        to_signed(2007, DATA_WIDTH), -- i=2  (14.03 deg)
        to_signed(1016, DATA_WIDTH), -- i=3  (7.12 deg)
        to_signed( 510, DATA_WIDTH), -- i=4  (3.57 deg)
        to_signed( 255, DATA_WIDTH), -- i=5  (1.79 deg)
        to_signed( 128, DATA_WIDTH), -- i=6  (0.89 deg)
        to_signed(  64, DATA_WIDTH), -- i=7
        to_signed(  32, DATA_WIDTH), -- i=8
        to_signed(  16, DATA_WIDTH), -- i=9
        to_signed(   8, DATA_WIDTH), -- i=10
        to_signed(   4, DATA_WIDTH), -- i=11
        to_signed(   2, DATA_WIDTH), -- i=12
        to_signed(   1, DATA_WIDTH), -- i=13
        to_signed(   0, DATA_WIDTH), -- i=14 (Hassasiyet bittiği için 0 olabilir)
        to_signed(   0, DATA_WIDTH)  -- i=15
    );
    -- CORDIC Kazanç Sabiti (K = 0.607...)
    -- Bunu da ölçeklenmiş tam sayı olarak yazmalısın (Örn: 0.607 * 2^15)
    constant K_CONSTANT : signed(DATA_WIDTH-1 downto 0) := to_signed(4975, DATA_WIDTH);
    
                                                       
    -- SİNYALLER
    signal x_reg, y_reg : signed(DATA_WIDTH-1 downto 0);
    
    -- Z REG GÜNCELLEMESİ: 
    -- Q1.15 formatı +-1.0 radyan üstünü tutamaz. 
    -- Bu yüzden Z register'ı işlem sırasında taşmasın diye 2 bit genişletiyoruz (Q3.15 gibi davranacak)
    signal z_reg : signed(DATA_WIDTH+1 downto 0); 
    
    signal current_iter : integer range 0 to ITERATIONS;
    
    type state_type is (IDLE, CALCULATE, FINISHED);
    signal state : state_type := IDLE;

begin

process(clk, rst)
-- Değişkenler (Variable) anlık hesaplar için process içinde tanımlanabilir
    variable x_shift, y_shift : signed(DATA_WIDTH-1 downto 0);
    variable z_extended_lut : signed(DATA_WIDTH+1 downto 0);
begin
    if rst = '1' then
        -- DURUM SIFIRLAMA
        state <= IDLE;
        
        -- İÇ REGISTERLARI SIFIRLAMA
        x_reg <= (others => '0');
        y_reg <= (others => '0');
        z_reg <= (others => '0');
        
        -- ÇIKIŞLARI SIFIRLAMA (UUUU hatasını çözen kısım burası!)
        sin_out <= (others => '0'); 
        cos_out <= (others => '0');
        done    <= '0';
        
    elsif rising_edge(clk) then
        case state is
            
            when IDLE =>
                done <= '0';
                if start = '1' then
                    current_iter <= 0;
                    y_reg <= (others => '0'); -- Y her zaman 0 başlar
                    state <= CALCULATE;
                    
                   
                    -- ROTATION MODE QUADRANT CORRECTION (BÖLGE DÜZELTMESİ)
                   
                    
                    if angle_in > DEG_90 then
                        -- Durum 1: Açı > 90 (Örn: 135 derece)
                        -- Füzeyi baştan 180 dereceye koy (X = -K)
                        -- Açıyı 180 azalt (135 - 180 = -45)
                        x_reg <= -K_CONSTANT; 
                        z_reg <= resize(angle_in, DATA_WIDTH+2) - DEG_180;
                        
                    elsif angle_in < DEG_NEG_90 then
                        -- Durum 2: Açı < -90 (Örn: -135 derece)
                        -- Füzeyi yine 180 dereceye koy (X = -K)
                        -- Açıya 180 ekle (-135 + 180 = +45)
                        x_reg <= -K_CONSTANT;
                        z_reg <= resize(angle_in, DATA_WIDTH+2) + DEG_180;
                        
                    else
                        -- Durum 3: Açı Normal Aralıkta (-90 ile +90 arası)
                        -- Standart başlangıç (X = +K)
                        x_reg <= K_CONSTANT;
                        z_reg <= resize(angle_in, DATA_WIDTH+2);
                    end if;
                end if;

            when CALCULATE =>
                -- Shift (Aritmetik kaydırma - İşaret korunur)
                x_shift := shift_right(x_reg, current_iter);
                y_shift := shift_right(y_reg, current_iter);
                
                -- LUT değerini de Z ile aynı boyuta genişlet (Sign extend)
                z_extended_lut := resize(ANGLE_LUT(current_iter), DATA_WIDTH+2);

                -- Yön Kararı (Z'nin en anlamlı bitine bak - MSB)
                if z_reg(z_reg'high) = '0' then -- Pozitif
                    x_reg <= x_reg - y_shift;
                    y_reg <= y_reg + x_shift;
                    z_reg <= z_reg - z_extended_lut;
                else -- Negatif
                    x_reg <= x_reg + y_shift;
                    y_reg <= y_reg - x_shift;
                    z_reg <= z_reg + z_extended_lut;
                end if;

                if current_iter = ITERATIONS-1 then
                    state <= FINISHED;
                else
                    current_iter <= current_iter + 1;
                end if;

            when FINISHED =>
                sin_out <= y_reg;
                cos_out <= x_reg;
                done <= '1';
                state <= IDLE;
                
        end case;
    end if;
end process;

end Behavioral;