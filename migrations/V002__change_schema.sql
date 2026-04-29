ALTER TABLE product 
    ADD COLUMN IF NOT EXISTS price double precision;

UPDATE product AS p
SET price = pi.price
FROM product_info AS pi
WHERE pi.product_id = p.id
    AND (p.price IS NULL OR p.price IS DISTINCT FROM pi.price)

DROP TABLE IF EXISTS product_info;

ALTER TABLE orders 
    ADD COLUMN IF NOT EXISTS date_created DATE default current_date;

UPDATE orders AS o
SET date_created = od.date_created
FROM orders_date AS od
WHERE od.order_id = o.id
    AND (o.date_created IS NULL OR o.date_created IS DISTINCT FROM od.date_created)

UPDATE orders
SET date_created = current_date
WHERE date_created IS NULL;

DROP TABLE IF EXISTS orders_date;

ALTER TABLE product 
    ADD CONSTRAINT pk_product PRIMARY KEY (id);

ALTER TABLE orders 
    ADD CONSTRAINT pk_orders PRIMARY KEY (id);

ALTER TABLE order_product
    ADD CONSTRAINT fk_order_product_order_id
    FOREIGN KEY (order_id) REFERENCES orders (id);

ALTER TABLE order_product
    ADD CONSTRAINT fk_order_product_product_id
    FOREIGN KEY (product_id) REFERENCES product (id);
