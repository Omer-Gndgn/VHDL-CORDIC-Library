library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL; -- Grafik ve Matematik için Şart

entity tb_VectoringMode is
end tb_VectoringMode;

architecture Behavioral of tb_VectoringMode is

    -- SİNYALLER (Donanım)
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal start     : std_logic := '0';
    signal x_in      : signed(15 downto 0) := (others => '0');
    signal y_in      : signed(15 downto 0) := (others => '0');
    signal x_out     : signed(15 downto 0);
    signal y_out     : signed(15 downto 0);
    signal angle_out : signed(15 downto 0);
    signal done      : std_logic;

    -- GRAFİK SİNYALLERİ (Simülasyon - Debug)
    -- Vivado Waveform'da bunları izleyeceğiz
    signal debug_angle_deg : real := 0.0; -- Hesaplanan Açı (Derece)
    signal debug_mag_out   : real := 0.0; -- Hesaplanan Büyüklük
    signal debug_x_input   : real := 0.0; -- Girilen X
    signal debug_y_input   : real := 0.0; -- Girilen Y

    -- SABİTLER
    constant CLK_PERIOD   : time := 10 ns;
    constant SCALE_FACTOR : real := 8192.0; -- Q3.13 Formatı (2^13)

begin

    -- DUT BAĞLANTISI (Entity Instantiation)
    uut: entity work.VectoringMode
        generic map ( 
            DATA_WIDTH => 16, 
            ITERATIONS => 16 
        )
        port map (
            clk       => clk,
            rst       => rst,
            start     => start,
            x_in      => x_in,
            y_in      => y_in,
            x_out     => x_out,
            y_out     => y_out,
            angle_out => angle_out,
            done      => done
        );

    
    
    -- 1. Açıyı (Radyan Q3.13) -> Dereceye Çevir
    -- Formül: (Integer / 8192) * (180 / PI)
    debug_angle_deg <= real(to_integer(angle_out)) / SCALE_FACTOR * (180.0 / MATH_PI);

    -- 2. Çıkış Büyüklüğünü Reale Çevir (CORDIC Gain dahil halidir)
    debug_mag_out <= real(to_integer(x_out)) / SCALE_FACTOR;

    -- Saat Üretimi
    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Test Senaryosu
    stim_proc: process
        
        -- YARDIMCI PROSEDÜR: Vektör (X,Y) girmeyi kolaylaştırır
        procedure set_vector(x_val : in real; y_val : in real) is
            variable x_int, y_int : integer;
        begin
            -- Debug sinyallerini güncelle
            debug_x_input <= x_val;
            debug_y_input <= y_val;

            -- Real -> Q3.13 Integer Çevrimi
            x_int := integer(x_val * SCALE_FACTOR);
            y_int := integer(y_val * SCALE_FACTOR);
            
            x_in <= to_signed(x_int, 16);
            y_in <= to_signed(y_int, 16);
            
            wait for CLK_PERIOD; 
            start <= '1';
            wait for CLK_PERIOD; 
            start <= '0';
            
            wait until done = '1';
            wait for 50 ns; 
        end procedure;

    begin
        -- BAŞLANGIÇ
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 20 ns;

        
        -- ORANSAL NAVİGASYON SENARYOLARI
        -- Koordinatları gir (X, Y), o sana AÇIYI bulsun.

        -- 1. Test: 45 Derece (X=1.0, Y=1.0)
        -- Beklenen Açı: ~45.0
        set_vector(1.0, 1.0);

        -- 2. Test: 30 Derece (X=1.0, Y=0.577)
        -- Tan(30) = 0.577
        -- Beklenen Açı: ~30.0
        set_vector(1.0, 0.577);

        -- 3. Test: 90 Derece (X=0.0, Y=1.0) - SINIR ZORLAMA
        -- Q3.13 formatı sayesinde bunu hesaplayabilir!
        -- Beklenen Açı: ~90.0
        set_vector(0.001, 1.0); -- X'e tam 0 yerine çok küçük sayı vermek daha güvenlidir

        -- 4. Test: -45 Derece (X=1.0, Y=-1.0)
        -- Beklenen Açı: -45.0
        set_vector(1.0, -1.0);

        -- 5. Test: 135 Derece (X=-1.0, Y=1.0) - FÜZE ARKASINA BAKIYOR
        -- Bu test Q3.13 formatının gerçek gücünü gösterir (90 üzeri)
        -- Beklenen Açı: ~135.0
        set_vector(-1.0, 1.0);

        wait;
    end process;

end Behavioral;