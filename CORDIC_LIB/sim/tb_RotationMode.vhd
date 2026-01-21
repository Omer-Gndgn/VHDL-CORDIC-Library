library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Grafik çizdirme ve matematiksel hesaplar için GEREKLİ kütüphane
use IEEE.MATH_REAL.ALL;

entity tb_RotationMode1 is
end tb_RotationMode1;

architecture Behavioral of tb_RotationMode1 is
    
    -- Sinyaller (Donanım Tarafı)
    signal clk      : std_logic := '0';
    signal rst      : std_logic := '0';
    signal start    : std_logic := '0';
    signal done     : std_logic;
    signal angle_in : signed(15 downto 0) := (others => '0');
    signal sin_out  : signed(15 downto 0);
    signal cos_out  : signed(15 downto 0);
    
    
    signal debug_angle_deg : real := 0.0; -- Girilen Açı (Derece)
    signal debug_sin_val   : real := 0.0; -- Hesaplanan Sinüs (Reel)
    signal debug_cos_val   : real := 0.0; -- Hesaplanan Kosinüs (Reel)

    -- SABİTLER
    constant CLK_PERIOD : time := 10 ns;
    
    -- Q3.13 Formatı için Ölçek (2^13 = 8192)
    -- Eğer Q1.15 kullansaydık burası 32768.0 olacaktı.
    constant SCALE_FACTOR : real := 8192.0;

begin

   
    uut: entity work.RotationMode 
        generic map ( 
            DATA_WIDTH => 16, 
            ITERATIONS => 16 
        )
        port map (
            clk      => clk, 
            rst      => rst, 
            start    => start,
            angle_in => angle_in,
            sin_out  => sin_out, 
            cos_out  => cos_out,
            done     => done
        );

  
    -- Çıkan binary sonucu anlık olarak 8192'ye bölüp Real'e çevirir.
    debug_sin_val <= real(to_integer(sin_out)) / SCALE_FACTOR;
    debug_cos_val <= real(to_integer(cos_out)) / SCALE_FACTOR;

    -- Saat Üretimi
    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Test Senaryosu
    stim_proc: process
        
        -- YARDIMCI PROSEDÜR: Açı girmeyi kolaylaştırır
        procedure set_angle(degrees : in real) is
            variable rad : real;
            variable fixed_val : integer;
        begin
            -- 1. Debug sinyaline yaz (Grafikte görmek için)
            debug_angle_deg <= degrees;
            
            -- 2. Dereceyi Radyana Çevir
            rad := degrees * MATH_PI / 180.0;
            
            -- 3. Radyanı Q3.13 Fixed Point Tamsayıya Çevir
            fixed_val := integer(rad * SCALE_FACTOR);
            
            -- 4. Girişe Ata ve Start Ver
            angle_in <= to_signed(fixed_val, 16);
            
            wait for CLK_PERIOD; -- Veri yerleşsin
            start <= '1';
            wait for CLK_PERIOD; -- Start pulse
            start <= '0';
            
            -- 5. İşlem bitene kadar bekle
            wait until done = '1';
            wait for 50 ns; 
        end procedure;

    begin
        -- BAŞLANGIÇ
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 20 ns;

        
        
        -- Pozitif Açılar
        set_angle(30.0);    -- 30 Derece
        set_angle(45.0);    -- 45 Derece
        set_angle(60.0);    -- 60 Derece 
        set_angle(90.0);    -- 90 Derece 
        
        -- Negatif Açılar 
        set_angle(-30.0);   -- -30 Derece
        set_angle(-60.0);   -- -60 Derece
        set_angle(135.0);

        
        wait;
    end process;

end Behavioral;