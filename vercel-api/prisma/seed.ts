import { seedFoods } from '../lib/seedFoods';

seedFoods()
  .then((r) => {
    console.log(r.message);
    process.exit(0);
  })
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
