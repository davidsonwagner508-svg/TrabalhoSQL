CREATE DATABASE IF NOT EXISTS tranzacoes;
USE tranzacoes;

CREATE TABLE produtos (
    id_produto INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(25) NOT NULL,
    estoque INT NOT NULL DEFAULT 0
);

CREATE TABLE vendas (
    id_venda INT PRIMARY KEY AUTO_INCREMENT,
    id_produto INT NOT NULL,
    quantidade INT NOT NULL,
    FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);

CREATE TABLE log_cancelados (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_produto INT NOT NULL,
    descricao VARCHAR(512),
    FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);

INSERT INTO produtos (nome, estoque) VALUES
('Maçã', 23),
('Banana', 30),
('Melancia', 18),
('Cebola', 40);

DELIMITER $$

CREATE PROCEDURE venda_registrada(
    IN p_id_produto INT,
    IN p_quantidade INT
)
BEGIN
    DECLARE v_estoque INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT estoque
    INTO v_estoque
    FROM produtos
    WHERE id_produto = p_id_produto
    FOR UPDATE;

    IF v_estoque IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Produto não encontrado.';
    END IF;

    IF v_estoque < p_quantidade THEN
        INSERT INTO log_cancelados (id_produto, descricao)
        VALUES (
            p_id_produto,
            CONCAT('Venda cancelada: estoque insuficiente. Solicitado: ',
                   p_quantidade, ', disponível: ', v_estoque)
        );

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Estoque insuficiente.';
    END IF;

    INSERT INTO vendas (id_produto, quantidade)
    VALUES (p_id_produto, p_quantidade);

    UPDATE produtos
    SET estoque = estoque - p_quantidade
    WHERE id_produto = p_id_produto;

    COMMIT;
END$$

DELIMITER ;