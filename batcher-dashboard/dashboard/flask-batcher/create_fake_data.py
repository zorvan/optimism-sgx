import secrets
import random
import sys
from faker import Faker
from ajax_table import db, Batcher


def create_fake_data(n):
    """Generate fake data."""
    faker = Faker()
    for i in range(n):
        batch = Batcher(
                    txid='0x' + secrets.token_hex(32),
                    blocknumber=random.randint(20000, 80000),
                    blockhash='0x' + secrets.token_hex(32),
                    timestamp=faker.date_time().strftime("%m/%d/%Y, %H:%M:%S"))

        db.session.add(batch)
    db.session.commit()
    print(f'Added {n} fake data to the database.')


if __name__ == '__main__':
    if len(sys.argv) <= 1:
        print('Pass the number of batches you want to create as an argument.')
        sys.exit(1)
    create_fake_data(int(sys.argv[1]))
