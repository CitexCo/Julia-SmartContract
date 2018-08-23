import assertRevert from './helpers/assertRevert'
const BurnQueue = artifacts.require('BurnQueue')

contract('BurnQueue', function ([_, owner, account2, account3]) {
    beforeEach(async function () {
        this.queue = await BurnQueue.new({ from: owner })
    })

    describe('when the sender is the owner', function () {
        const from = owner

        it('push', async function () {
            await this.queue.push(account2, 100, 100, { from })
            const count = await this.queue.count({ from })
            assert.equal(count, 1)
        })

        it('pop', async function () {
            await this.queue.push(account2, 100, 100, { from })
            await this.queue.push(account3, 1000, 1000, { from })
            await this.queue.pop({ from })
            const count = await this.queue.count({ from })
            assert.equal(count, 1)
        })

        it('count', async function () {
            await this.queue.push(account2, 100, 100, { from })
            await this.queue.push(account3, 1000, 1000, { from })
            await this.queue.pop({ from })
            await this.queue.pop({ from })
            await this.queue.push(account2, 100, 100, { from })
            await this.queue.pop({ from })
            await assertRevert(this.queue.pop({ from }))

            await this.queue.push(account2, 100, 100, { from })
            await this.queue.push(account3, 1000, 1000, { from })
            await this.queue.push(account3, 200, 1, { from })
            await this.queue.pop({ from })
            await this.queue.pop({ from })

            const count = await this.queue.count({ from })
            assert.equal(count, 1)
        })

        it('totalDebt', async function () {
            await this.queue.push(account2, 100, 100, { from })
            await this.queue.push(account3, 1000, 1000, { from })

            const debt = await this.queue.totalDebt({ from })
            assert.equal(debt, 100*100 + 1000*1000)
        })
    })

    describe('when the sender is not the owner', function () {
        const from = account2
        it('reverts all calls', async function () {
            await assertRevert(this.queue.push(account2, 100, 100, { from }))
            await assertRevert(this.queue.pop({ from }))
            await assertRevert(this.queue.count({ from }))
            await assertRevert(this.queue.totalDebt({ from }))
        })
    })
})
