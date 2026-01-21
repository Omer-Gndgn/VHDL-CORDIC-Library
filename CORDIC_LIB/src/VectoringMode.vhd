library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VectoringMode is
    Generic (
        DATA_WIDTH : integer := 16; 
        ITERATIONS : integer := 16   
    );
    Port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        start     : in  std_logic;
        x_in      : in  signed(DATA_WIDTH-1 downto 0); 
        y_in      : in  signed(DATA_WIDTH-1 downto 0);
   
        x_out     : out signed(DATA_WIDTH-1 downto 0);
        y_out     : out signed(DATA_WIDTH-1 downto 0);
        angle_out : out signed(DATA_WIDTH-1 downto 0);
        done      : out std_logic
    );
end VectoringMode;

architecture Behavioral of VectoringMode is

    -- Q3.13 Formatı (8192 Ölçekli)
    type angle_lut_type is array (0 to ITERATIONS-1) of signed(DATA_WIDTH-1 downto 0);
    constant ANGLE_LUT : angle_lut_type := (
        to_signed(6433, DATA_WIDTH), to_signed(3798, DATA_WIDTH), 
        to_signed(2007, DATA_WIDTH), to_signed(1016, DATA_WIDTH), 
        to_signed( 510, DATA_WIDTH), to_signed( 255, DATA_WIDTH), 
        to_signed( 128, DATA_WIDTH), to_signed(  64, DATA_WIDTH), 
        to_signed(  32, DATA_WIDTH), to_signed(  16, DATA_WIDTH), 
        to_signed(   8, DATA_WIDTH), to_signed(   4, DATA_WIDTH), 
        to_signed(   2, DATA_WIDTH), to_signed(   1, DATA_WIDTH), 
        to_signed(   0, DATA_WIDTH), to_signed(   0, DATA_WIDTH)
    );

    -- 180 Derece (Pi Sayısı) Q3.13 Karşılığı
    -- 3.14159 * 8192 = 25736
    constant PI_VAL : signed(DATA_WIDTH+1 downto 0) := to_signed(25736, DATA_WIDTH+2);

    -- Sinyaller
    signal x_reg, y_reg : signed(DATA_WIDTH-1 downto 0);
    signal z_reg : signed(DATA_WIDTH+1 downto 0); -- Genişletilmiş Z
    signal current_iter : integer range 0 to ITERATIONS;
    
    type state_type is (IDLE, CALCULATE, FINISHED);
    signal state : state_type := IDLE;

begin

process(clk, rst)
    variable x_shift, y_shift : signed(DATA_WIDTH-1 downto 0);
    variable z_extended_lut : signed(DATA_WIDTH+1 downto 0);
begin
    if rst = '1' then
        state <= IDLE;
        x_reg <= (others => '0');
        y_reg <= (others => '0');
        z_reg <= (others => '0');
        x_out <= (others => '0');
        y_out <= (others => '0');
        angle_out <= (others => '0');
        done  <= '0';
        
    elsif rising_edge(clk) then
        case state is
            
            when IDLE =>
                done <= '0';
                if start = '1' then
                    current_iter <= 0;
                    state <= CALCULATE;

                    
                    if x_in >= 0 then
                        -- 1. ve 4. Bölge (Normal Durum)
                        x_reg <= x_in;
                        y_reg <= y_in;
                        z_reg <= (others => '0');
                    else
                        -- 2. ve 3. Bölge (X Negatif ise)
                        -- Vektörü 180 derece çevirip (X, Y ters işaret),
                        -- Başlangıç açısına 180 ekliyoruz.
                        x_reg <= -x_in; -- X'i Pozitif yap
                        y_reg <= -y_in; -- Y'yi Ters çevir
                        
                        if y_in >= 0 then
                            z_reg <= PI_VAL;  -- +180 Derece'den başla
                        else
                            z_reg <= -PI_VAL; -- -180 Derece'den başla
                        end if;
                    end if;
                end if;

            when CALCULATE =>
                -- Shift İşlemleri
                x_shift := shift_right(x_reg, current_iter);
                y_shift := shift_right(y_reg, current_iter);
                z_extended_lut := resize(ANGLE_LUT(current_iter), DATA_WIDTH+2);

                -- Klasik CORDIC Mantığı
                if y_reg(DATA_WIDTH - 1) = '1' then -- Y Negatif ise
                    x_reg <= x_reg - y_shift; 
                    y_reg <= y_reg + x_shift; 
                    z_reg <= z_reg - z_extended_lut; 
                else -- Y Pozitif ise
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
                x_out <= x_reg;
                y_out <= y_reg; 
                angle_out <= resize(z_reg, DATA_WIDTH);
                done <= '1';
                state <= IDLE;
                
        end case;
    end if;
end process;

end Behavioral;